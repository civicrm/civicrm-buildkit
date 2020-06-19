#!/bin/bash

###########################################################
## Bootstrap

set -e
BINDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
BKNIXSRC=$(dirname "$BINDIR")
cd "$BKNIXSRC"
source "$BINDIR/../lib/common.sh"

###########################################################
## Constants

OWNER=${OWNER:-jenkins}
RAMDISK="/mnt/mysql/$OWNER"
RAMDISKSVC=$(systemd-escape "mnt/mysql/$OWNER")

###########################################################
## Utilities

function uninstall_ramdisk() {
  echo "Removing systemd ramdisk \"$RAMDISK\" ($RAMDISKSVC)"
  systemctl daemon-reload
  systemctl stop "$RAMDISKSVC.mount"
  systemctl disable "$RAMDISKSVC.mount"
  rm -f "/etc/systemd/system/${RAMDISKSVC}.mount"
}

function uninstall_profile() {
  PRFDIR="/nix/var/nix/profiles/bknix-$PROFILE"
  BKNIXDIR="/home/$OWNER/bknix-$PROFILE"
  for SYSTEMSVC in "bknix-$PROFILE" "bknix-$PROFILE-mysqld" ; do
    if [ -f "/etc/systemd/system/${SYSTEMSVC}.service" ]; then
      echo "Removing systemd service \"$SYSTEMSVC\""
      systemctl stop "$SYSTEMSVC"
      systemctl disable "$SYSTEMSVC"
      rm -f "/etc/systemd/system/${SYSTEMSVC}.service"
      systemctl daemon-reload
    else
      echo "Skipping unrecognize service \"$SYSTEMSVC\""
    fi
  done

  echo "NOT IMPLEMENTED: Remove data dir $BKNIXDIR"
  echo "NOT IMPLEMENTED: Remove profile $PRFDIR"
}

########################################
## Main

check_reqs

SVCS=$(get_svcs)
RAMDISKS=$(get_ramdisk_svcs)

echo "Stopping services:$SVCS"
[ -n "$SVCS" ] && systemctl stop $SVCS

## This is slightly aggressive...
set +e
  killall php-fpm
  killall mysqld
set -e

echo "Waiting"
# Don't know if this is actually needed, but it's improved reliability in the past.
sleep 5

echo "Stopping ramdisks:$RAMDISKS"
[ -n "$RAMDISKS" ] && systemctl stop $RAMDISKS

echo "Clearing old service definitions"
for SVC in $SVCS ; do rm -f "/etc/systemd/system/$SVC.service" ; done
for SVC in $RAMDISKS ; do rm -f "/etc/systemd/system/$SVC" ; done

systemctl daemon-reload

for OWNER in jenkins publisher ; do
  for FOLDER in $(get_bkits_by_user $OWNER) ; do
    echo "Found old buildkit: $FOLDER"
  done
done
