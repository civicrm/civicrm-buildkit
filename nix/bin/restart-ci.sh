#!/bin/bash
set -e

###########################################################
## Bootstrap

BINDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
BKNIXSRC=$(dirname "$BINDIR")
cd "$BKNIXSRC"
source "$BINDIR/../lib/common.sh"

###########################################################
## Helpers

GUARD=

function do_stop() {
  echo "Stopping all services: $(get_svcs)"
  $GUARD systemctl stop $(get_svcs)
  $GUARD sleep 3 # Don't know if this is actually needed, but it's improved reliability in the past.
  echo "Stopping all ramdisks: $(get_ramdisk_svcs)"
  $GUARD systemctl stop $(get_ramdisk_svcs)
}


function do_start() {
  echo "Starting all ramdisks: $(get_ramdisk_svcs)"
  $GUARD systemctl start $(get_ramdisk_svcs)
  $GUARD sleep 3 # Don't know if this is actually needed, but it's improved reliability in the past.
  echo "Starting all services: $(get_svcs)"
  $GUARD systemctl start $(get_svcs)
}

###########################################################
## Main

assert_root_user

case "$1" in
  stop) do_stop ;;
  start) do_start ;;
  status) systemctl status $(get_svcs) $(get_ramdisk_svcs) ;;
  ""|restart)
    do_stop
    echo "Waiting"
    $GUARD sleep 3 # Don't know if this is actually needed, but it's improved reliability in the past.
    do_start
    ;;
  *)
    echo "unrecognized action: $1"
    exit 1
    ;;
esac
