#!/bin/bash

## This is a full reset - shutting down all systems, recreating all config files, and restarting all systems
##
## NOTE: reset-ci.sh and reset-gcloud.sh should be kept in sync. TODO: DRY

set -e

function get_svcs() {
  for svc in bknix{,-publisher}-{dfl,min,max,old,edge}{,-mysqld} ; do
    if [ -f "/etc/systemd/system/$svc.service" ]; then
      echo -n " $svc"
    fi
  done
}

function get_ramdisk_svcs() {
  for svc in mnt-mysql-jenkins.mount mnt-mysql-publisher.mount ; do
    if [ -f "/etc/systemd/system/$svc" ]; then
      echo -n " $svc"
    fi
  done
}

SVCS=$(get_svcs)
RAMDISKS=$(get_ramdisk_svcs)

echo "Stopping services:$SVCS"
systemctl stop $SVCS

## This is slightly aggressive, but the scripts in `pkgs/launcher` don't seem to do a good job of shutting down php-fpm.
set +e
  killall php-fpm
  killall mysqld
set -e

echo "Waiting"
# Don't know if this is actually needed, but it's improved reliability in the past.
sleep 5

echo "Stopping ramdisks:$RAMDISKS"
systemctl stop $RAMDISKS

echo "Reinstalling profiles"
FORCE_INIT=-f ./bin/install-gcloud.sh

echo "Starting ramdisks:$RAMDISKS"
systemctl start $RAMDISKS

echo "Starting services:$SVCS"
systemctl start $SVCS

echo "Updating buildkit"
./bin/update-ci-buildkit.sh

echo "Warming up caches"
./bin/cache-warmup.sh
