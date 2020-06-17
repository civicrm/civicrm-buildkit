#!/bin/bash
set -e

OWNER=${OWNER:-jenkins}
RAMDISK="/mnt/mysql/$OWNER"
RAMDISKSVC=$(systemd-escape "mnt/mysql/$OWNER")

########################################
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

if [ -z `which nix` ]; then
  echo "Please install \"nix\" before running this. See: https://nixos.org/nix/manual/"
  exit 2
fi

echo TODO: Revise/retest with arrbuk

#PROFILE=dfl HTTPD_DOMAIN=$(hostname -f) HTTPD_PORT=8001 MEMCACHED_PORT=12221 PHPFPM_PORT=9009 REDIS_PORT=6380 uninstall_profile
#PROFILE=min HTTPD_DOMAIN=$(hostname -f) HTTPD_PORT=8002 MEMCACHED_PORT=12222 PHPFPM_PORT=9010 REDIS_PORT=6381 uninstall_profile
#PROFILE=max HTTPD_DOMAIN=$(hostname -f) HTTPD_PORT=8003 MEMCACHED_PORT=12223 PHPFPM_PORT=9011 REDIS_PORT=6382 uninstall_profile
#EDGE# PROFILE=edge HTTPD_DOMAIN=$(hostname -f) HTTPD_PORT=8004 MEMCACHED_PORT=12224 PHPFPM_PORT=9012 REDIS_PORT=6383 uninstall_profile
#OLD#  PROFILE=old  HTTPD_DOMAIN=$(hostname -f) HTTPD_PORT=8005 MEMCACHED_PORT=12225 PHPFPM_PORT=9013 REDIS_PORT=6384 uninstall_profile
#uninstall_ramdisk

#echo "NOT IMPLEMENTED: Remove /usr/local/bin/use-bknix"
