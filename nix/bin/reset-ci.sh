#!/bin/bash

## This is a full reset - shutting down all systems, recreating all config files, and restarting all systems
##
## NOTE: reset-ci.sh and reset-gcloud.sh should be kept in sync. TODO: DRY

set -e

###########################################################
## Utils

function get_svcs() {
  for svc in bknix{,-jenkins,-publisher}-{dfl,min,max,old,edge}{,-apache-vdr,-buildkit,-mailcatcher,-mysql,-mysqld,-php-fpm,-redis} ; do
    if [ -f "/etc/systemd/system/$svc.service" ]; then
      echo -n " $svc"
    fi
  done
}

function get_ramdisk_svcs() {
  for svc in mnt-mysql-jenkins.mount mnt-mysql-publisher.mount 'home-jenkins-.bknix\x2dvar.mount' 'home-publisher-.bknix\x2dvar.mount'; do
    if [ -f "/etc/systemd/system/$svc" ]; then
      echo -n " $svc"
    fi
  done
}

###########################################################
## Main

if [ -z "$1" -o ! -d "$PWD/examples/$1" ]; then
  echo "usage: ./bin/reset-ci.sh <template-name>"
  echo "The <template-name> should correspond to a folder in examples/"
  exit 1
else
  BKNIX_CI_TEMPLATE="$1"
fi

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

echo "Reinstalling profiles"
FORCE_INIT=-f ./bin/install-ci.sh "$BKNIX_CI_TEMPLATE"

echo "Re-scanning service names"
SVCS=$(get_svcs)
RAMDISKS=$(get_ramdisk_svcs)

echo "Starting ramdisks:$RAMDISKS"
systemctl start $RAMDISKS

echo "Starting services:$SVCS"
systemctl start $SVCS

echo "Updating buildkit"
./bin/update-ci-buildkit.sh

echo "Warming up caches"
./bin/cache-warmup.sh
