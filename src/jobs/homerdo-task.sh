#!/usr/bin/env bash
{
## This adapter allows `run-bknix-jobs` to isolate Jenkins jobs with `homerdo`.
## General flow:
##
## - Jenkins connects via SSH. It passes a bunch of variables and calls `run-bknix-job`.
## - `run-bknix-job` detects `homerdo` and asks `homerdo-task.sh all` to forward the job.
## - `homerdo-task.sh request` captures the request-environment and stores it as a file.
## - `homerdo-task.sh pick-image` loads or creates a home-image (eg `bknix-max-0.img`).
## - `homerdo-task.sh setup` performs basic maintenance on `bknix-max-0.img` (eg `civi-download-tools`)
## - `homerdo-task.sh exec` loads `bknix-max-0.img`, executes the test-job, and transfers
##   any new artifacts from `~homer/$WORKSPACE` to `~mainuser/$WORKSPACE`.

#####################################################################
## Internal Environment
##
## BKNIX_JOBS=   ## This folder (containing the *.job scripts)
## REQUEST=      ## File with the serialized request
## BKIT=         ## Path for the active buildkit instance

SELF="$0"
TTL_TOOLS=60     ## During setup, refresh 'civi-download-tools' (if >1 hour old)
TTL_BLDTYPE=180  ## During setup, warmup 'bldtype' (if >3 hours since last)
CLEANUP_FILES=() ## List of files/directories to delete
RESPONSE=        ## Tar-formatted fifo
MAX_IMAGES=8     ## If there are more than X copies of an image, then refuse to make more

#####################################################################
## Main
function main() {
  trap on_shutdown EXIT
  case "$1" in
    all)         do_all ; ;;
    request)     do_request ; ;;
    pick-image)  REQUEST="$2" ; load_request "$REQUEST" ; do_pick_image "$3" ; ;;
    setup)       REQUEST="$2" ; load_request "$REQUEST" ; do_setup ; ;;
    exec)        REQUEST="$2" ; load_request "$REQUEST" ; RESPONSE="$3" ; do_exec ; ;;
  esac
}

function on_shutdown() {
  if [ -n "$RESPONSE" ]; then
    if [ -d "$WORKSPACE" ]; then
      echo >&2 "Send results"
      (cd "$WORKSPACE" && tar cvf "$RESPONSE" .)
    else
      echo >&2 "Cannot send results. No workspace ($WORKSPACE)."
      tar cf "$RESPONSE" -T /dev/null
    fi
  fi

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

  local workdir=$(make_temp .d)
  mkdir "$workdir" && chmod 700 "$workdir" && setfacl -m u:homer:--x "$workdir"
  CLEANUP_FILES+=("$workdir")

  local request="$workdir/request-$RANDOM$RANDOM.env"
  local response="$workdir/response-$RANDOM$RANDOM.tar"
  touch "$request"   && setfacl -m u:homer:r-- "$request"
  mkfifo "$response" && setfacl -m u:homer:rw- "$response"

  "$SELF" request > "$request"

  local img=$(cd "$imageDir" && flock . "$SELF" pick-image "$request" $$ )
  if [ ! -e "$img" ]; then
    echo >&2 "Failed to pick image from $imageDir for $request"
    exit 1
  fi
  echo >&2 "[$USER] Found home-image $img"
  # echo >&2 "[$USER] Prepared job (img=$img, request=$request, response=$response)"

  set -e
  homerdo -i "$img" -- "$SELF" setup "$request"
  set +e

  (cd "$WORKSPACE" && tar xf "$response") &
  local tarpid=$!
  homerdo -A -i "$img" --temp -- "$SELF" exec "$request" "$response"
  local result=$?
  wait $tarpid
  exit $result
}

#####################################################################
## TASK: New Request
## USER: (anyone)
## EXAMPLE: `homerdo-task.sh request > /tmp/request-1234.txt`
##
## Generate a request message. This will be relayed to other subtasks.

function do_request() {
  echo >&2 "[$USER] Generate request"
  env | known_variables | switch_home
}

#####################################################################
## TASK: Pick image
## USER: (anyone)
## USAGE: `homerdo-task.sh pick-image <REQUEST> <PID>`
## EXAMPLE: `cd $IMGDIR && flock . homerdo-task.sh pick-image /tmp/request-1234.txt $$`
##
## Choose which image-file to use as homer's $HOME.
## NOTE: For concurrent invocations, run this with `flock`.

function do_pick_image() {
  echo >&2 "[$USER] Finding home-image in $PWD..."
  local OWNER_PID="$1"

  if [ -z "$OWNER_PID" ]; then
    echo >&2 "ERROR: Missing OWNER_PID"
    exit 3
  fi

  local n=-1
  local img
  local is_new
  local status
  local img_lock

  while true; do
    n=$((1 + $n))
    img="bknix-$BKPROF-$n.img"
    img_lock="$img.lock"
    # echo >&2 "check $n: $img"

    if [[ $n -ge $MAX_IMAGES ]]; then
      echo >&2 "Too many images already exist. (BKPROF=$BKPROF, n=$n, MAX_IMAGES=$MAX_IMAGES)"
      exit 1
    fi

    if [ ! -e "$img" -a ! -e "$img_lock" ]; then
      # echo >&2 "claim $n: $img (new)"
      is_new=1
      break ## OK
    fi

    if [ -f "$img_lock" ]; then
      #echo >&2 "consider lock $img_lock"
      local their_pid=$(cat "$img_lock")
      if ps -p "$their_pid" > /dev/null; then
        #echo >&2 "not $img ($img_lock)"
        continue ## Nope, someone else still using it
      fi
    fi

    #echo >&2 "consider status of $img"
    status=$(homerdo status -i "$img")
    if [ "$status" != "avail" ]; then
      #echo >&2 "not $img ($status)"
      continue ## Nope, someone else still  using it
    fi

    ## OK. Someone else had it, but we can take it
    #echo >&2 "claim $n: $img (reuse)"
    is_new=
    break
  done

  echo "$OWNER_PID" > "$img_lock"
  if [ ! -e "$img" ]; then
    homerdo create -i "$img" >&2
  fi

  realpath "$img"
}

#####################################################################
## TASK: Setup Base Layer
## USER: "homer"
## HOME FILE MODE: "Base"
## EXAMPLE: `homerdo-task.sh setup /tmp/request-1234.txt > /tmp/my-log.txt`
##
## Use this to download common tools or warm-up common caches. Anything you
## do during "setup" will may be re-used in future calls.
##
## Do not use this for the heavy-lifting of job execution. You probably
## should NOT retrieve any unapproved/PR content.

function do_setup() {
  echo >&2 "[$USER] Run setup for request $REQUEST"

  git config --global user.email "$USER@example.com"
  git config --global user.name "$USER"
  mkdir -p "$HOME/.cache-flags"

  if [ ! -d "$BKIT" ]; then
    git clone https://github.com/civicrm/civicrm-buildkit "$BKIT"
  fi

  if is_stale "$BKIT/.ttl-tools" "$TTL_TOOLS" ; then
    (cd "$BKIT" && git pull)
    # (cd "$BKIT" && nix-shell -A "$BKPROF" --run './bin/civi-download-tools')
    (cd "$BKIT" && nix-shell -A "$BKPROF" --run './bin/civi-download-tools && civibuild cache-warmup')
    touch "$BKIT/.ttl-tools"
  fi

  ## Every few hours, the "setup" does a trial run to re-warm caches.
  ## (It might preferrable to get composer+npm to use a general HTTP cache, but this will work for now.)
  safe_delete "$BKIT/build/warmup" "$BKIT/build/warmup.sh"
  if [[ -d "$BKIT/app/config/$BLDTYPE" && "$BLDTYPE" =~ ^(drupal|drupal8|drupal9|backdrop|wp|standalone)-(empty|clean|demo)$ ]]; then
    local flag_file="$BKIT/.ttl-$BLDTYPE"
    if is_stale "$flag_file" "$TTL_BLDTYPE" ; then
      safe_delete "$BKIT/build/warmup" "$BKIT/build/warmup.sh"
      (cd "$BKIT" && nix-shell -A "$BKPROF" --run "civibuild download warmup --type $BLDTYPE")
      safe_delete "$BKIT/build/warmup" "$BKIT/build/warmup.sh"
      touch "$flag_file"
    fi
  fi

  # echo "EXEC: Start pre-setup shell. Press Ctrl-D to finish pre-run shell." && bash
}

#####################################################################
## TASK: Execute job
## USER: "homer"
## HOME FILE MODE: "Temp"
## EXAMPLE: `homerdo-task.sh exec /tmp/request-1234.txt > /tmp/my-log.txt`
##
## Use this to do the heavy-lifting of job execution. You might create
## new sites, run PHPUnit, etc.
##
## You will be allowed to write files anywhere in "$HOME", but they will be
## reset when the job finishes.

function do_exec() {
  echo >&2 "[$USER] Run exec for request $REQUEST"

  # echo "EXEC: Start pre-run shell. Press Ctrl-D to finish pre-run shell." && bash

  use_workspace
  mkdir build
  cd build
  pwd
  cat "$REQUEST" > env-requested.txt
  cat "$REQUEST" | well_formed_variables | known_variables > env-effective.txt

  cd "$BKIT"
  cat ".loco/worker-n.yml" | grep -v CIVI_TEST_MODE > ".loco/loco.yml"
  local cmd=$(printf "run-bknix-job --loaded %q" "$BKPROF")
  nix-shell -A "$BKPROF" --run "$cmd"

  # echo "EXEC: Start post-run shell. Press Ctrl-D to finish post-run shell." && nix-shell -A "$BKPROF"
}

#####################################################################
## Utilities

## Ensure that the WORKSPACE folder is setup.
function use_workspace() {
  echo >&2 "Use workspace ($WORKSPACE)"
  if [ -z "$WORKSPACE" ]; then
    echo >&2 "Error: Missing WORKSPACE"
    exit 1
  fi
  if [ ! -d "$WORKSPACE" ]; then
    mkdir -p "$WORKSPACE"
  fi
  cd "$WORKSPACE"
}

## Load data from a request file.
## usage: load_request <REQ_FILE>
function load_request() {
  #eval $( cat "$1" | well_formed_variables | new_variables | escape_variables )
  eval $( cat "$1" | well_formed_variables | known_variables | escape_variables )

  case "$BKPROF" in
    old|min|dfl|max|edge)
      BKIT="$HOME/buildkit"
      ;;
    *)
      echo >&2 "Unrecognized BKPROF=[$BKPROF]"
      exit 3
      ;;
  esac
}

function well_formed_variables() {
  grep -v '^#' | grep '^[a-zA-Z0-9_]\+='
}

## Filter the variables. Only return new/undefined values.
##
## STDIN: List of KEY=VALUE pairs (unescaped values)
## STDOUT: List of KEY=VALUE pairs (unescaped values)
function new_variables() {
  while IFS= read -r line; do
    var=$(echo "$line" | cut -d= -f1)
    if [[ -z "${!var}" ]]; then
      echo "$line"
    fi
  done

}

## Filter the variable. Only return well-known (pre-declared) variables.
##
## STDIN: List of KEY=VALUE pairs (unescaped values)
## STDOUT: List of KEY=VALUE pairs (unescaped values)
function known_variables() {
  env_list=" "$( echo $( cat "$BKNIX_JOBS/env.txt" | grep '^[a-zA-Z0-9_]\+$' ; echo ))" "
  #echo >&2 "$JOBDIR/env.txt: $env_list"
  while IFS= read -r line; do
    var=$(echo "$line" | cut -d= -f1)
    if [[ "$env_list" =~ " $var " ]]; then
      echo "$line"
    fi
  done
}

## Filter any variables that refer to `~dispatcher` and plug in our own user.
function switch_home() {
  local old_home="$HOME"
  local new_home="/home/homer"
  sed "s;$old_home;$new_home;"
}


## Encode the variables in a way that's suitable for "eval"
##
## STDIN: List of KEY=VALUE pairs (unescaped values)
## STDOUT: List of KEY=VALUE pairs (escaped values; suited for "eval")
function escape_variables() {
  local my_exports=()

  while IFS= read -r line; do
    var=$(echo "$line" | cut -d= -f1)
    val=$(echo "$line" | cut -d= -f2-)
    printf "$var=%q\n" "$val"
    my_exports+=( "$var" )
  done

  if [ ${#my_exports[@]} -gt 0 ]; then
    echo "export ${my_exports[@]}"
  fi
}

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

function make_temp() {
  local suffix="$1"
  local tmpfile="/tmp/run-bknix-$USER-"$(date '+%Y-%m-%d-%H-%M'-$RANDOM$RANDOM)"$suffix"
  echo "$tmpfile"
}

function absdirname() {
  pushd $(dirname $0) >> /dev/null
    pwd
  popd >> /dev/null
}

#####################################################################
## Go

export BKNIX_JOBS=$(absdirname "$0")
main "$@"
exit $?
}
