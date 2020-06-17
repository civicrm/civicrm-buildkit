#!/bin/bash
GUARD=

set -e

function get_svcs() {
  for svc in bknix{,-publisher}-{dfl,min,max,old,edge}{,-mysqld} ; do
    if [ -f "/etc/systemd/system/$svc.service" ]; then
      echo -n " $svc"
    fi
  done
}
function get_ramdisks() {
  for svc in mnt-mysql-{jenkins,publisher}.mount ; do
    if [ -f "/etc/systemd/system/$svc" ]; then
      echo -n " $svc"
    fi
  done
}

function do_stop() {
  echo "Stopping all services: $(get_svcs)"
  $GUARD systemctl stop $(get_svcs)
  $GUARD sleep 3 # Don't know if this is actually needed, but it's improved reliability in the past.
  echo "Stopping all ramdisks: $(get_ramdisks)"
  $GUARD systemctl stop $(get_ramdisks)
}


function do_start() {
  echo "Starting all ramdisks: $(get_ramdisks)"
  $GUARD systemctl start $(get_ramdisks)
  $GUARD sleep 3 # Don't know if this is actually needed, but it's improved reliability in the past.
  echo "Starting all services: $(get_svcs)"
  $GUARD systemctl start $(get_svcs)
}

case "$1" in
  stop) do_stop ;;
  start) do_start ;;
  status) systemctl status $(get_svcs) $(get_ramdisks) ;;
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
