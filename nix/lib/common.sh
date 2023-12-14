#!/usr/bin/env bash

###########################################################

# Current v2.2.1 suffers https://github.com/NixOS/nix/issues/2633 (eg on Debain Stretch/gcloud). Use v2.0.4.
# But 2.0.4 may not be working on macOS Mojave. Blerg.
NIX_INSTALLER_URL="https://nixos.org/releases/nix/nix-2.0.4/install"
# NIX_INSTALLER_URL="https://nixos.org/releases/nix/nix-2.2.1/install"

DISPATCH_USER=dispatcher

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
  echo "\"nix\" is a package manager for Unix-style software."
  echo ""
  echo "It is open-source, multi-platform, multi-user, and reproducible. It allows multiple"
  echo "versions of any package to coexist, and it does not interfere with your regular package"
  echo "manager. For more background, see:"
  echo ""
  echo "  - https://nixos.org/nix/about.html"
  echo "  - https://nixos.org/download.html"
  echo ""
  echo "This script will run the standard installer for \"nix\". However, compatibility"
  echo "and configuration may vary based on the version, host-environment, and use-case."
  echo "You will have a chance to fine-tune some options."
  echo ""
  echo "== Nix Version"
  echo ""
  echo "- Example: \"2.8.1\""
  echo "- Tip: To use the latest release, leave this blank."
  echo "- Tip: At time of writing, install-developer.sh and install-ci.sh have issues with nix 2.14+"
  ## Specifically, "/nix/var/nix/profiles/per-user/$USER" doesn't seem to be available anymore. Needs update to support new layout.
  echo ""
  echo "Which version of \"nix\" would you like to install?"
  read -p '> ' BK_NIX_VERSION

  if [ -n "$BK_NIX_VERSION" ]; then
    BK_NIX_URL="https://nixos.org/releases/nix/nix-${BK_NIX_VERSION}/install"
  else
    BK_NIX_URL=https://nixos.org/nix/install
  fi

  echo ""
  echo "== Installation Flags"
  echo
  echo "- Tip: If you leave this blank, the installer will make its own guesses."
  echo "- Tip: Some versions and host environments may require specific flags."
  echo "- Example: \"--daemon\""
  echo "- Example: \"--no-daemon\""
  echo "- Example: \"--no-daemon --darwin-use-unencrypted-nix-store-volume\""
  echo "- Tip: For full-time servers, \"--daemon\" is strongly preferred."
  echo "- Docs: https://nixos.org/manual/nix/stable/installation/installation.html"
  echo ""
  echo "Please enter any installation-flags (or leave blank):"
  read -p'> ' BK_NIX_OPT

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
  SPLIT_BUILDKIT=1

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
  SPLIT_BUILDKIT=1

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

## usage: install_bin_url <url> <dest-cache-file> <dest-symlink-file>
## example: install_bin_url https://storage.googleapis.com/civicrm/util-linux/unshare-2.38.1.bin /usr/local/lib/unshare-2.38.1.bin /usr/local/bin/unshare
function install_bin_url() {
  local BIN_URL="$1"
  local BIN_PATH="$2"
  local SYMLINK_PATH="$3"

  if [ -e "$BIN_PATH" ] && [ -L "$SYMLINK_PATH" ] && [ "$(readlink "$SYMLINK_PATH")" == "$BIN_PATH" ]; then
    true
  else
    echo "Downloading $BIN_URL"
    curl -o "$BIN_PATH" "$BIN_URL"
    chmod +x "$BIN_PATH"
    echo "Creating symlink $SYMLINK_PATH -> $BIN_PATH"
    ln -sf "$BIN_PATH" "$SYMLINK_PATH"
  fi
}

## usage: pick_buildkit_path <USER> <PROFILE>
function pick_buildkit_path() {
  if [ "x1" = "x$SPLIT_BUILDKIT" ]; then
    echo "/home/$1/bknix-$2"
  else
    echo "/home/$1/bknix"
  fi
}

## Setup the binaries, data folder, and service for a given profile.
##
## Pre-condition:
##   PROFILE is a name like "min" or "max"
##   SPLIT_BUILDKIT=1 is a boolean
##   Optionally, HTTPD_PORT, MEMCACHED_PORT, PHPFPM_PORT, REDIS_PORT are set
function install_profile() {
  PRFDIR=$(get_nix_profile_path "bknix-$PROFILE")
  BKIT=$(pick_buildkit_path "$OWNER" "$PROFILE")
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
    local svcs=$( cd /etc/systemd/system/ && ls ${PREFIX}*service | sed 's;\.service$;;' )
    if [ -z "$SYSTEMD_ENABLE" -o "yes" == "$SYSTEMD_ENABLE" ]; then
      systemctl enable $svcs
    else
      systemctl disable $svcs
    fi
    if [ -z "$SYSTEMD_START" -o "yes" == "$SYSTEMD_START" ]; then
      systemctl start ${PREFIX}
    fi

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

function install_dispatcher() {
  if ! getent group "${DISPATCH_USER}" >/dev/null ; then
    echo "Create group ${DISPATCH_USER}"
    addgroup "${DISPATCH_USER}"
  fi

  if ! getent passwd "${DISPATCH_USER}" >/dev/null ; then
    echo "Create user ${DISPATCH_USER}"
    adduser "${DISPATCH_USER}" --gecos "Bkrun Dispatcher" --ingroup "${DISPATCH_USER}" --disabled-password
  fi

  local ssh_dir="/home/${DISPATCH_USER}/.ssh"
  local authorized_keys="$(cat /etc/bknix-ci/dispatcher-keys)"

  if [ ! -d "$ssh_dir" ]; then
    mkdir -p "$ssh_dir"
  fi
  chown "root:${DISPATCH_USER}" "$ssh_dir"
  chmod 750 "$ssh_dir"

  echo "$authorized_keys" > "$ssh_dir/authorized_keys"
  chown "root:${DISPATCH_USER}" "$ssh_dir/authorized_keys"
  chmod 640 "$ssh_dir/authorized_keys"

  echo -n > /etc/sudoers.d/dispatcher
  #echo "Defaults:${DISPATCH_USER} env_keep+=SSH_AUTH_SOCK" >> /etc/sudoers.d/dispatcher
  echo "${DISPATCH_USER} ALL = (root) NOPASSWD: NOSETENV: /usr/local/bin/homerdo" >> /etc/sudoers.d/dispatcher
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
      ## Work-around: package-lock.json is particularly prone to get weird/uncommitted changes.
      [ -f package-lock.json ] && git checkout -- package-lock.json
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
  if [ -n "$YAML" ]; then
    eval $( loco env -c "$YAML" --export)
    loco-buildkit-init
  fi
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

  local BKIT=$(pick_buildkit_path "$OWNER" "$PROFILE")
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

function sync_folder() {
  local src="$1"
  local tgt="$2"
  if [ ! -d "$tgt" ]; then
    echo "Initializing $tgt"
    mkdir -p "$tgt"
  fi

  echo "Syncing from $src to $tgt"
  rsync -va "$src/./" "$tgt/./"
}

function template_render() {
  cat "$1" \
    | sed "s;%%RAMDISK%%;$RAMDISK;g" \
    | sed "s;%%RAMDISKSVC%%;$RAMDISKSVC;g" \
    | sed "s;%%RAMDISKSIZE%%;$RAMDISKSIZE;g" \
    | sed "s/%%OWNER%%/$OWNER/g" \
    | sed "s/%%PROFILE%%/$PROFILE/g"
}

## This step will download the binaries for our profiles, but
## it doesn't install them in any particular place. I suppose
## it could be done, but they're not supposed to be used.
## Never-the-less, we should warmup the nix caches.
function warmup_binaries() {
  pushd "$BKNIXSRC" >>/dev/null
    set +e
      ## replace old ones
      rm -f ./result*
    set -e

    nix-build -E 'let p=import ./profiles; in builtins.attrValues p' | sort -u
    nix-instantiate default.nix | sort -u
    nix-store -r $( ( for PRF in old min dfl max edge; do nix-instantiate -A profiles.$PRF default.nix ; done ) | sort -u )

    ## the extra "./result*" files are messy, but we'll leave them to prevent GC
    ## from hitting frequently-used packages
  popd >> /dev/null
}

## If the dispatcher has an work-images like `bknix-dfl-0.img`, then copy to `bknix-dfl-1.img`.
## Repeat for {min,dfl,max,edge} and numbers {1,2}.
function warmup_dispatcher_images() {
  local images="/home/${DISPATCH_USER}/images"
  for prf in min dfl max alt edge ; do
    for destnum in 1 2 ; do
      local src="$images/bknix-$prf-0.img"
      local dest="$images/bknix-$prf-$destnum.img"
      if [ -e "$src" -a ! -e "$dest" ]; then
        echo "Generate $dest"
        cp -p "$src" "$dest"
      fi
    done
  done
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
  for SUBDIR in bknix-old bknix-min bknix-dfl bknix-max bknix-alt bknix-edge ; do
    for DIR in "/home/$OWNER/$SUBDIR" "/Users/$OWNER/$FOLDER" ; do
      if [ -d "$DIR" ]; then
        echo $DIR
      fi
    done
  done
}

## usage: install_xfce4_launchers
function install_xfce4_launchers() {
  local desktop="$HOME/Desktop"
  local buildkit=$( dirname "$BKNIXSRC")
  local share="$BKNIXSRC/share/desktop-xfce4"

  echo "Symlink README.md"
  ln -sf "$share/README.md" "$desktop/README.md"

  for PRF in dfl min max alt edge old ; do
    if [ -e "$HOME/.local/state/nix/profiles/bknix-$PRF" -o -e "/nix/var/nix/profiles/per-user/cividev/bknix-$PRF" -o -e "/nix/var/nix/profiles/bknix-$PRF" ]; then
      echo "Enable bknix-$PRF.desktop"
      cat "$share/bknix-$PRF.desktop" \
        | sed "s;{{BUILDKIT}};$buildkit;g" \
        > "$desktop/bknix-$PRF.desktop"
      chmod +x "$desktop/bknix-$PRF.desktop"
    else
      echo "Disable bknix-$PRF.desktop"
      [ -f "$desktop/bknix-$PRF.desktop" ] && rm -f "$desktop/bknix-$PRF.desktop"
    fi
  done

  for file in mailhog.desktop site-list.desktop ; do
    echo "Copy $file"
    cp "$share/$file" "$desktop/$file"
  done

  if [ ! -e  "$BKNIXSRC/etc/bashrc.local" ]; then
    echo "Copy bashrc.local"
    [ ! -d "$BKNIXSRC/etc" ] && mkdir "$BKNIXSRC/etc"
    ln -sf "$share/bashrc.local" "$BKNIXSRC/etc/bashrc.local"
  fi

  echo "Sync civicrm.settings.d"
  if [ ! -d /etc/civicrm.settings.d ]; then
    sudo mkdir /etc/civicrm.settings.d
    sudo chown $USER /etc/civicrm.settings.d
  fi
  if [ ! -e "/etc/civicrm.settings.d/000-global.php" ]; then
    cp "$share/civicrm.settings.d/000-global.php" "/etc/civicrm.settings.d/000-global.php"
    ln -sf "/etc/civicrm.settings.d/000-global.php" "$desktop/000-global.php"
  fi
}

## Determine the location of the profile dir
## Ex: "get_nix_profile_path bknix-dfl" ==> "/nix/var/nix/profiles/per-user/myuser/bknix-dfl"
function get_nix_profile_path() {
  if [ "$USER" == "root" ]; then
    echo "/nix/var/nix/profiles/$1"
  elif [ -e "$HOME/.local/state/nix/profiles" ]; then
    echo "$HOME/.local/state/nix/profiles/$1"
  elif [ -e "/nix/var/nix/profiles/per-user/$USER" ]; then
    echo "/nix/var/nix/profiles/per-user/$USER/$1"
  else
    echo >&2 "get_nix_profile_base(): Failed to determine base"
    exit 2
  fi
}
