#!/usr/bin/env bash
{
## Run a "homerdo" environment with a smorgasbord of daemons for demo purposes.
## General flow:
##
## - Systemd starts up the homerdo-demo env (`~/images/demo.img`)
##    - `homerdo-demo.sh setup` initializes and/or updates image
##    - `homerdo-demo.sh exec` starts sshd (port 992), mysqld, etc.
## - Jenkins connects via SSH.
## - Jenkins jobs call `use-bknix` and `civibuild` to create demos
##
## Characteristics:
##
## - Baseline cache stored on-disk (as part of image)
## - All demos run in same container
## - Demo data stored temporarily (ramdisk)

#####################################################################
## Internal Environment
##

SELF="$0"                ## Path to the current script
CLEANUP_CALLS=()         ## List of functions to call during shutdown
CLEANUP_FILES=()         ## List of files/directories to delete

## How big should make the data-storage?
SIZE=50g
# SIZE=10g

## List of buildkit profiles to enable
#ALL_PROFILES=(min max)
#ALL_PROFILES=(min dfl max)
ALL_PROFILES=(min dfl max alt edge)

## List of buildkit types for which we want warm caches
WARMUP_TYPES=(standalone-clean)
#WARMUP_TYPES=(standalone-clean drupal-demo wp-demo)

## How frequently should we bake-in cache updates?
TTL_TOOLS=120            ## During setup, refresh 'civi-download-tools' (if >120 minutes old)
TTL_BLDTYPE=1440         ## During setup, warmup 'bldtype' (if >24 hours since last)

## Configure sshd for the demo environment
SSHD_PORT=9022
SSHD_AUTHORIZED=/etc/bknix-ci/dispatcher-keys

BKIT_REPO="https://github.com/civicrm/civicrm-buildkit"
BKIT_BRANCH="master"
#BKIT_REPO="https://github.com/totten/civicrm-buildkit"
#BKIT_BRANCH="master-demo-2"

#####################################################################
## Main
function main() {
  trap on_shutdown EXIT
  case "$1" in
    all)         do_all ; ;;
    setup)       do_setup ; ;;
    exec)        do_exec ; ;;
    *)           echo >&2 "usage: $0 <all|setup|exec>" ; exit 1;
  esac
}

function on_shutdown() {
  for CLEANUP_CALL in "${CLEANUP_CALLS[@]}" ; do
    eval "$CLEANUP_CALL"
  done

  safe_delete "${CLEANUP_FILES[@]}"
}

#####################################################################
## TASK: Do the entire process!
## USER: (anyone)
## EXAMPLE: `JOB_NAME=FooBar BKPROF=min homer-do-task.sh`
function do_all() {
  local imageDir="$HOME/images"

  if [ ! -d "$imageDir" ]; then
    mkdir -p "$imageDir"
  fi

  local img="$imageDir/demo.img"
  echo >&2 "[$USER] Chose home-image $img"

  set -e
  homerdo --size "$SIZE" -i "$img" -- "$SELF" setup
  homerdo --size "$SIZE" -i "$img" --temp -- "$SELF" exec
}

#####################################################################
## TASK: Setup Base Layer
## USER: "homer"
## HOME FILE MODE: "Base"
## EXAMPLE: `homerdo-task.sh setup > /tmp/my-log.txt`
##
## Use this to download common tools or warm-up common caches. Anything you
## do during "setup" will may be re-used in future calls.
##
## Do not use this for the heavy-lifting of job execution. You probably
## should NOT retrieve any unapproved/PR content.

function do_setup() {
  echo >&2 "[$USER] Run setup"
  umask 022

  git config --global user.email "$USER@example.com"
  git config --global user.name "$USER"
  mkdir -p "$HOME/.cache-flags"

  sshd_setup

  for BKPROF in "${ALL_PROFILES[@]}" ; do
    profile_setup "$BKPROF"
    profile_warmup "$BKPROF" "${WARMUP_TYPES[@]}"
  done

  # echo "EXEC: Start pre-setup shell. Press Ctrl-D to finish pre-run shell." && bash
}

#####################################################################
## TASK: Execute job
## USER: "homer"
## HOME FILE MODE: "Temp"
## EXAMPLE: `homerdo-task.sh exec > /tmp/my-log.txt`
##
## Use this to launch the various daemons. In particular:
##
## - For each active profile, call "loco start" to run in background
## - Start sshd in foreground
## - Once sshd stops, call "loco stop"

function do_exec() {
  echo >&2 "[$USER] Run exec"
  umask 022

  echo starting > "$HOME/.demo-status"

  # echo "EXEC: Start pre-run shell. Press Ctrl-D to finish pre-run shell." && bash

  for BKPROF in "${ALL_PROFILES[@]}" ; do
    profile_start "$BKPROF"
    CLEANUP_CALLS+=( "profile_stop $BKPROF" )
  done

  proxy_start
  CLEANUP_CALLS+=( proxy_stop )

  use-bknix min -r civibuild create site-list
  ## TIP: Put extra config in /etc/site-list.settings.d/post.d/demo.php. Ex:
  ##   $GLOBALS['civibuild']['SITE_TOKEN'] = 'mYrAnDoM';
  ##   $GLOBALS['sitelist']['bldDirs'] = glob(getenv('HOME') . '/bknix*/build');
  ##   $GLOBALS['sitelist']['moreSites'] = ['http://site-list.remote.example.com' => 'ThEiRsEcReT']

  echo started > "$HOME/.demo-status"

  # echo "EXEC: Start post-run shell. Press Ctrl-D to finish post-run shell." && bash
  sshd_run
}

#####################################################################
## Manage profiles

## ex: profile_start min
function profile_start() {
  local BKPROF="$1"
  local BKIT="$HOME/bknix-$BKPROF"
  ( cd "$BKIT" && export BKPROF="$BKPROF" && nix-shell nix/bare.nix -A "$BKPROF" --run "loco start -c .loco/demo.yml" )
}

## ex: profile_stop max
function profile_stop() {
  local BKPROF="$1"
  local BKIT="$HOME/bknix-$BKPROF"
  ( cd "$BKIT" && export BKPROF="$BKPROF" && nix-shell nix/bare.nix -A "$BKPROF" --run "loco stop -c .loco/demo.yml" )
}

## ex: profile_setup min
function profile_setup() {
  local BKPROF="$1"
  local BKIT="$HOME/bknix-$BKPROF"

  echo > "$HOME/.bashrc"
  echo 'if [ -d "$HOME/bin" ] ; then PATH="$HOME/bin:$PATH" ; fi' >> "$HOME/.bashrc"
  cp -f "$HOME/.bashrc" "$HOME/.profile"

  if [ ! -d "$BKIT" ]; then
    git clone "$BKIT_REPO" -b "$BKIT_BRANCH" "$BKIT"
  fi

  if is_stale "$BKIT/.ttl-tools" "$TTL_TOOLS" ; then
    (cd "$BKIT" && git pull)
    mkdir -p "$HOME/bin"
    cp "$BKIT/nix/bin/use-bknix.demo" "$HOME/bin/use-bknix" ## We may overwrite a couple times. Don't care.
    # (cd "$BKIT" && nix-shell nix/bare.nix -A "$BKPROF" --run './bin/civi-download-tools')
    (cd "$BKIT" && nix-shell nix/bare.nix -A "$BKPROF" --run './bin/civi-download-tools && ./bin/civibuild cache-warmup')
    touch "$BKIT/.ttl-tools"
  fi
}

## usage: profile_warmup <BKPROF> [BLDTYPES...]
## ex: profile_warmup max drupal-demo wp-demo
function profile_warmup() {
  local BKPROF="$1"
  shift
  local BKIT="$HOME/bknix-$BKPROF"

  for BLDTYPE in "$@" ; do
    ## Every few hours, the "setup" does a trial run to re-warm caches.
    ## (It might preferrable to get composer+npm to use a general HTTP cache, but this will work for now.)
    safe_delete "$BKIT/build/warmup" "$BKIT/build/warmup.sh"
    if [[ -d "$BKIT/app/config/$BLDTYPE" && "$BLDTYPE" =~ ^(drupal|drupal8|drupal9|backdrop|wp|standalone)-(empty|clean|demo)$ ]]; then
      local flag_file="$BKIT/.ttl-$BLDTYPE"
      if is_stale "$flag_file" "$TTL_BLDTYPE" ; then
        safe_delete "$BKIT/build/warmup" "$BKIT/build/warmup.sh"
        (cd "$BKIT" && BKPROF="$BKPROF" nix-shell -A "$BKPROF" --run "./bin/civibuild download warmup --type $BLDTYPE")
        ## Note: For warmup, it's nice if it works - but doesn't matter much if it abends.
        safe_delete "$BKIT/build/warmup" "$BKIT/build/warmup.sh"
        touch "$flag_file"
      fi
    fi
  done
}

#####################################################################

function sshd_setup() {
  if [ ! -d "$HOME/.sshd" ]; then
    mkdir "$HOME/.sshd"
  fi
  pushd "$HOME/.sshd" >> /dev/null
    for keytype in rsa ecdsa ed25519 ; do
      if [ ! -e "db_${keytype}_host_key" ]; then
        nix-shell -p dropbear --run "dropbearkey -t "$keytype" -f db_${keytype}_host_key"
      fi
    done
  popd >> /dev/null
}

function sshd_run() {
  echo >&2 "Start SSHD (Port=$SSHD_PORT, AuthorizedKeysFile=$SSHD_AUTHORIZED)"
  mkdir -p "$HOME/.ssh"
  ln -sf "$SSHD_AUTHORIZED" "$HOME/.ssh/authorized_keys"

  pushd "$HOME/.sshd" >> /dev/null
    nix-shell -p dropbear --run "dropbear -F -E -w -p $SSHD_PORT -r db_ecdsa_host_key -r db_ed25519_host_key -r db_rsa_host_key -P dropbear.pid"
  popd >> /dev/null
}


#####################################################################

function proxy_start() {
  local BKPROF="max"
  local BKIT="$HOME/bknix-$BKPROF"
  ( cd "$BKIT/tools/demo-proxy" && nix-shell --run "loco start" )
}

function proxy_stop() {
  local BKPROF="max"
  local BKIT="$HOME/bknix-$BKPROF"
  ( cd "$BKIT/tools/demo-proxy" && nix-shell --run "loco stop" )
}

#####################################################################
## Utilities

## Check if it's time for an update
## usage: is_stale <MARKER> <MINUTES>
function is_stale () {
  local file_path="$1"
  local max_age_minutes="$2"

  if [[ ! -f "$file_path" ]]; then
    # File does not exist, so it's expired
    return 0
  fi

  local file_age_seconds=$(( $(date +%s) - $(stat -c %Y "$file_path") ))
  local max_age_seconds=$(( max_age_minutes * 60 ))

  if [[ $file_age_seconds -gt $max_age_seconds ]]; then
    # File is older than the specified max age
    return 0
  else
    # File is not older than the specified max age
    return 1
  fi
}

function safe_delete() {
  for FILE in "$@" ; do
    if [[ -f "$FILE" ]]; then
      rm "$FILE"
    elif [[ -d "$FILE" ]]; then
      rm -rf "$FILE"
    fi
  done
}

#####################################################################
## Go

main "$@"
exit $?
}
