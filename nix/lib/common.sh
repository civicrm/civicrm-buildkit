#!/bin/bash

###########################################################

# Current v2.2.1 suffers https://github.com/NixOS/nix/issues/2633 (eg on Debain Stretch/gcloud). Use v2.0.4.
# But 2.0.4 may not be working on macOS Mojave. Blerg.
NIX_INSTALLER_URL="https://nixos.org/releases/nix/nix-2.0.4/install"
# NIX_INSTALLER_URL="https://nixos.org/releases/nix/nix-2.2.1/install"

###########################################################
## Primary install routines

function install_nix_interactive() {
  if [ -d /nix ]; then
    echo "The /nix folder is already installed."
    return
  fi

  if [ -z "$(which curl)" ]; then
    echo "Missing required program: curl" >&2
    exit 1
  fi

  assert_not_root_user ## The nix installer will complain about root.

  echo "==== Installing nix ===="
  echo ""
  echo "'nix' is a package manager for Unix-style software."
  echo ""
  echo "It is open-source, multi-platform, multi-user, and reproducible. It allows multiple"
  echo "versions of any package to coexist, and it does not interfere with your regular package"
  echo "manager. For more background, see https://nixos.org/nix/about.html"
  echo ""
  echo "The nix installer will create a folder, /nix. It may run in a few modes:"
  echo ""
  echo "1. Single-user mode"
  echo "   - Suitable for Linux and older macOS."
  echo "   - The regular console user can directly edit files in /nix."
  echo "2. Single-user mode with Darwin volume (APFS)"
  echo "   - Suitable for newer macOS (Catalina 10.15+)."
  echo "   - The /nix folder will be stored in a separate volume."
  echo "   - The regular console user can directly edit files in /nix."
  echo "3. Multi-user mode"
  echo "   - Suitable for Linux and older macOS."
  echo "   - The /nix folder is restricted. It is managed transparently/securely by nix-daemon."
  echo "   - On Linux, it requires systemd."
  echo ""
  echo "For more details and for more advanced options, see https://nixos.org/nix/manual/"
  echo ""
  echo "To continue, please choose 1, 2, or 3. To abort, enter a blank value."

  read -p'> ' BK_NIX_INSTALL_MODE

  case "$BK_NIX_INSTALL_MODE" in
    1) BK_NIX_OPT="--no-daemon" ;;
    2) BK_NIX_OPT="--no-daemon --darwin-use-unencrypted-nix-store-volume" ;;
    3) BK_NIX_OPT="--daemon" ;;
    *)
      echo "Aborting"
      exit 1
      ;;
  esac

  echo ""
  echo "Which version of nix would like to install?"
  echo ""
  echo "Examples: 2.0.4, 2.2.1, 2.3.5"
  echo "To use the current stable, leave this blank."
  read -p '> ' BK_NIX_VERSION

  if [ -n "$BK_NIX_VERSION" ]; then
    BK_NIX_URL="https://nixos.org/releases/nix/nix-${BK_NIX_VERSION}/install"
  else
    BK_NIX_URL=https://nixos.org/nix/install
  fi

  echo
  ## Quirky "" prevents execution...
  echo "Running: sh <""(""curl -L $BK_NIX_URL"") $BK_NIX_OPT"
  sh <(curl -L $BK_NIX_URL) $BK_NIX_OPT

  if [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
    . "$HOME/.nix-profile/etc/profile.d/nix.sh"
  elif [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
    . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
  else
    echo "ERROR: Failed to find nix console script. Perhaps it has a different name now-a-days? You may need to restart console before continuing with any commands." 1>&2
    exit 1
  fi
}

function install_cachix() {
  if [ -f /etc/nix/nix.conf ]; then
    if grep -q bknix.cachix.org /etc/nix/nix.conf ; then
      return
    fi
  fi
  echo "Setup binary cache (cachix)"
  local SUDO
  is_my_file /nix/store && SUDO='' || SUDO='sudo -i'
  $SUDO nix-env -iA cachix -f https://cachix.org/api/v1/install
  $SUDO cachix use bknix
}

## Setup all services for user "jenkins"
function install_all_jenkins() {
  OWNER=jenkins
  RAMDISK="/home/$OWNER/_bknix/ramdisk"
  RAMDISKSVC=$(systemd-escape "home/$OWNER/_bknix/ramdisk")
  RAMDISKSIZE=8G
  PROFILES=${PROFILES:-dfl min max}
  HTTPD_DOMAIN=$(hostname -f)

  [ -f /etc/bknix-ci/install_all_jenkins.sh ] && source /etc/bknix-ci/install_all_jenkins.sh

  install_user "$OWNER"
  sudo -u "$OWNER" mkdir -p "/home/$OWNER/_bknix"
  install_ramdisk

  for PROFILE in $PROFILES ; do
    install_profile
  done

  unset OWNER RAMDISK RAMDISKSVC RAMDISKSIZE PROFILES PROFILE HTTPD_DOMAIN
}

## Setup all services for user "publisher"
function install_all_publisher() {
  OWNER=publisher
  RAMDISK="/home/$OWNER/_bknix/ramdisk"
  RAMDISKSVC=$(systemd-escape "home/$OWNER/_bknix/ramdisk")
  RAMDISKSIZE=500M
  PROFILES=""
  HTTPD_DOMAIN=$(hostname -f)

  [ -f /etc/bknix-ci/install_all_publisher.sh ] && source /etc/bknix-ci/install_all_publisher.sh

  install_user "$OWNER"
  sudo -u "$OWNER" mkdir -p "/home/$OWNER/_bknix"
  install_ramdisk

  for PROFILE in $PROFILES ; do
    install_profile
  done

  unset OWNER RAMDISK RAMDISKSVC RAMDISKSIZE PROFILES PROFILE HTTPD_DOMAIN
}

###########################################################
## Install helpers

function assert_root_user() {
  if [ "$USER" != "root" ]; then
    echo "This command must run as a super user - not a regular user!" 1>&2
    exit 1
  fi
}

function assert_not_root_user() {
  if [ "$USER" == "root" ]; then
    echo "This command must run as a regular user - not as root!" 1>&2
    exit 1
  fi
}

function check_reqs() {
  if [ -z `which nix` ]; then
   echo "Please install \"nix\" before running this. See: https://nixos.org/nix/manual/"
   echo
   echo "If you have already installed /nix, then there may be an issue with the shell setup."
   echo
   echo "- Try restarting the terminal/session."
   echo "- If the problem persists, you may need to manually update the ~/.profile or ~/.bashrc with a snippet like this:"
   echo
   echo "  if [ -e \"$HOME/.nix-profile/etc/profile.d/nix.sh\" ]; then"
   echo "    . \"$HOME/.nix-profile/etc/profile.d/nix.sh\""
   echo "  elif [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then"
   echo "    . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'"
   echo "  fi"
   exit 2
  fi
}

## Install a binary file
##
## usage: install_bin <src-path-relative> <dest-path-absolute>
## example: install_bin bin/foo /usr/local/bin/foo
function install_bin() {
  local src="$1"
  local dest="$2"
  local destdir=$(dirname "$dest")

  echo "Installing global helper (\"$src\" => \"$dest\")"
  [ ! -d "$destdir" ] && sudo mkdir "$destdir"
  sudo cp -f "$src" "$dest"
}

## Setup the binaries, data folder, and service for a given profile.
##
## Pre-condition:
##   PROFILE is a name like "min" or "max"
##   Optionally, HTTPD_PORT, MEMCACHED_PORT, PHPFPM_PORT, REDIS_PORT are set
function install_profile() {
  PRFDIR="/nix/var/nix/profiles/bknix-$PROFILE"
  BKIT="/home/$OWNER/bknix-$PROFILE"
  PREFIX="bknix-$OWNER-$PROFILE"

  install_profile_binaries "$PROFILE" "$PRFDIR"

  echo "Downloading buildkit folder \"$BKIT\""
  do_as_owner "$(declare -f download_buildkit)" download_buildkit "$PROFILE"

  echo "Setting up buildkit folder \"$BKIT\""
  do_as_owner "$(declare -f setup_buildkit)" setup_buildkit ".loco/$OWNER-$PROFILE.yml"

  if [ -z "$NO_SYSTEMD" ]; then
    install_profile_systemd "$OWNER" "$PROFILE"
  else
    echo "Skip: Creating/activating systemd services for \"$PREFIX\""
  fi
}

## Install just the binaries for a profile
##
## usage: install_profile_binaries <profile-name> <install-path>
## example: install_profile_binaries dfl /nix/var/nix/profiles/foobar
function install_profile_binaries() {
  local PROFILE="$1"
  local PRFDIR="$2"

  if [ -d "$PRFDIR" ]; then
    echo "Removing profile \"$PRFDIR\""
    nix-env -p "$PRFDIR" -e '.*'
  fi

  echo "Creating profile \"$PRFDIR\""
  nix-env -i -p "$PRFDIR" -f "$BKNIXSRC" -E "f: f.profiles.$PROFILE"
}

## Install a full copy of buildkit.
## usage: install_profile_systemd <user> <profile>
function install_profile_systemd() {
  local OWNER="$1"
  local PROFILE="$2"
  local SYSDTMP=$(tempfile -p bknix-systemd).d
  local PREFIX="bknix-$OWNER-$PROFILE"

  [ -z "$SYSDTMP" ] && echo "Failed to identify temp dir" && exit 99
  mkdir "$SYSDTMP"
  chown "$OWNER" "$SYSDTMP"

  echo "Generate systemd services for \"$PREFIX\" in \"$SYSDTMP\""

  function locogen() {
    set -ex
    cd "$BKIT"
    local YAML=".loco/$OWNER-$PROFILE.yml"
    loco init -c "$YAML"
    loco export -c "$YAML" --app="$1" --out="$2"
  }
  do_as_owner "$(declare -f locogen)" locogen "$PREFIX" "$SYSDTMP"

  set -x
    echo "Copy systemd services for \"$PREFIX\" to /etc/systemd/system/"
    for F in /etc/systemd/system/$PREFIX*.service ; do
      rm -f "$F"
    done
    cp "$SYSDTMP"/"$PREFIX"*.service /etc/systemd/system/

    echo "Activating systemd services for \"$PREFIX\""
    systemctl daemon-reload
    systemctl enable /etc/systemd/system/${PREFIX}*service
    systemctl start ${PREFIX}

    echo "Cleaning temp files"
    rm -rf "$SYSDTMP"
  set +x
}

## Create systemd ramdisk unit
##
## Pre-conditions/variable inputs:
## - RAMDISK: Path to the mount point
## - RAMDISKSVC: Name of systemd unit
## - (optional) NO_SYSTEMD
function install_ramdisk() {
  if [ -z "$NO_SYSTEMD" ]; then
    echo "Creating systemd ramdisk \"$RAMDISK\" ($RAMDISKSVC)"
    template_render "$BKNIXSRC/"examples/systemd.mount > "/etc/systemd/system/${RAMDISKSVC}.mount"
    systemctl daemon-reload
    systemctl start "$RAMDISKSVC.mount"
    systemctl enable "$RAMDISKSVC.mount"
  else
    echo "Skip: Creating systemd ramdisk \"$RAMDISK\" ($RAMDISKSVC)"
  fi
}

## Create the user, $OWNER
## usage: install_user <user>
function install_user() {
  local OWNER="$1"
  if id "$OWNER" 2>/dev/null 1>/dev/null ; then
    echo "User $OWNER already exists"
  else
    adduser --disabled-password "$OWNER"
  fi
}

## Initialize a copy of buildkit.
## NOTE: This runs as $OWNER by way of do_as_owner(). Do not rely on any sibling functions.
function download_buildkit() {
  set -ex
  local PROFILE="$1"
  cd "$HOME"

  if [ ! -d "$BKIT" ]; then
    git clone https://github.com/civicrm/civicrm-buildkit "$BKIT"
  else
    pushd "$BKIT"
      git pull
    popd
  fi
}

## Populate civibuild configuration and caches
## NOTE: This runs as $OWNER by way of do_as_owner(). Do not rely on any sibling functions.
## NOTE: This expects that civi-download-tools has already run.
function setup_buildkit() {
  set -ex
  local YAML="$1"
  cd "$BKIT"

  ./bin/civi-download-tools
  eval $( loco env -c "$YAML" --export)
  loco-buildkit-init
  civibuild cache-warmup
}

## Run a function in the context for the given owner/prfdir. For use with 'install-ci.sh' use-cases.
##
## NOTE: This will drop privileges
##
## Certain key variables -- BKIT, PROFILE, OWNER -- will propagate to the subshell.
## The PATH will automaically be set to include the PRFDIR.
##
## usage: do_as_owner <function-body> <function-call...>
## ex: do_as_owner "$(declare -f foobar)" foobar "Hello world"
function do_as_owner() {
  ## Ex (input): _escape_args "Hello World" "Alice Bobson"
  ## Ex (output): Hello\ World Alice\ Bobson
  function _escape_args() {
    for v in "$@" ; do printf "%q " "$v" ; done
  }

  local BKIT="/home/$OWNER/bknix-$PROFILE"
  local FUNC="$1"
  shift

  sudo su - "$OWNER" -c "export PATH=\"$PRFDIR/bin:$PATH\" BKIT=\"$BKIT\" PROFILE=\"$PROFILE\" OWNER=\"$OWNER\" ; cd \$HOME ; eval \$( bknix-profile env ) ; $FUNC; $(_escape_args "$@")"
}

## Run a function in the context for given owner/prfdir, where the owner is... me, the current user/developer. For use with 'install-developer.sh' use-cases.
function do_as_dev() {
  ## Ex (input): _escape_args "Hello World" "Alice Bobson"
  ## Ex (output): Hello\ World Alice\ Bobson
  function _escape_args() {
    for v in "$@" ; do printf "%q " "$v" ; done
  }

  local BKIT=$( dirname "$BKNIXSRC" )
  local FUNC="$1"
  shift

  [ -z "$PRFDIR" ] && echo "WARNING: No PRFDIR!"
  bash -c "export PATH=\"$PRFDIR/bin:$PATH\" BKIT=\"$BKIT\" PROFILE=\"$PROFILE\" OWNER=\"$OWNER\" ; cd \$HOME ; eval \$( bknix-profile env ) ; $FUNC; $(_escape_args "$@")"
}

## Determine if a file is owned by the current user
##
## usage: if is_my_file "/path/to/foo/bar" ; then ... fi
function is_my_file() {
  local tgt="$1"

  ## Crude heuristic: Darwin systems have BSD userland in /bin and /usr/bin. Everything else is GNU.
  if [ "$(uname -s)" == "Darwin" ]; then
    ## Be explicit about /usr/bin bc we don't know if sysadmin has supplemented with GNU toolchain.
    local ownerid=$( /usr/bin/stat -f "%u" "$tgt" )
  else
    local ownerid=$( stat -c "%u" "$tgt" )
  fi
  local myid=$( id -u )
  [ "$myid" == "$ownerid" ] && return 0 || return 1
}


## usage: init_folder <src-folder> <tgt-folder>
## If the target folder doesn't exist, create it (by copying the source folder).
## ex: init_folder "$PWD/examples/gcloud-bknix-ci" "/etc/bknix-ci"
function init_folder() {
  local src="$1"
  local tgt="$2"
  if [ ! -d "$tgt" ]; then
    echo "Initializing $tgt using $src"
    mkdir "$tgt"
  fi

  echo "Identifying new files in $tgt using $src"
  rsync -va --ignore-existing "$src/./" "$tgt/./"
}

function template_render() {
  cat "$1" \
    | sed "s;%%RAMDISK%%;$RAMDISK;g" \
    | sed "s;%%RAMDISKSVC%%;$RAMDISKSVC;g" \
    | sed "s;%%RAMDISKSIZE%%;$RAMDISKSIZE;g" \
    | sed "s/%%OWNER%%/$OWNER/g" \
    | sed "s/%%PROFILE%%/$PROFILE/g"
}

###########################################################
## Scanners

function get_svcs() {
  for svc in bknix{,-jenkins,-publisher}-{dfl,min,max,old,edge}{,-apache-vdr,-buildkit,-mailcatcher,-mysql,-mysqld,-php-fpm,-redis} ; do
    if [ -f "/etc/systemd/system/$svc.service" ]; then
      echo -n " $svc"
    fi
  done
}

function get_ramdisk_svcs() {
  for svc in mnt-mysql-jenkins.mount mnt-mysql-publisher.mount 'home-jenkins-.bknix\x2dvar.mount' 'home-publisher-.bknix\x2dvar.mount' home-jenkins-_bknix-ramdisk.mount home-publisher-_bknix-ramdisk.mount ; do
    if [ -f "/etc/systemd/system/$svc" ]; then
      echo -n " $svc"
    fi
  done
}

function get_bkits_by_user() {
  local OWNER="$1"
  for SUBDIR in bknix-old bknix-min bknix-dfl bknix-max bknix-edge ; do
    for DIR in "/home/$OWNER/$SUBDIR" "/Users/$OWNER/$FOLDER" ; do
      if [ -d "$DIR" ]; then
        echo $DIR
      fi
    done
  done
}
