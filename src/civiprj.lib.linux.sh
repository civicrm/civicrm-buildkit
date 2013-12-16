#!/bin/bash

function setup_ram_disk() {
  if [ ! -e $TMPFS_DIR ]; then
    mkdir -p $TMPFS_DIR
  fi
  TMPFS_DIR=`realpath $TMPFS_DIR`
  if stat -f -c '%T' $TMPFS_DIR | grep -q tmpfs; then
    return
  fi
  sudo mount -t tmpfs -o size=500m tmpfs $TMPFS_DIR
  uid=`id -u`
  gid=`id -g`
  sudo chown $uid:$gid $TMPFS_DIR
  apparmor_file_path=/etc/apparmor.d/local/usr.sbin.mysqld
  add_apparmor_lines=0
  if [ -e $apparmor_file_path ]; then
    if ! grep -q "^$TMPFS_DIR/ r,\$" $apparmor_file_path; then
      add_apparmor_lines=1
    fi
  else
    add_apparmor_lines=1
  fi
  if [ -n $add_apparmor_lines  ]; then
    sudo cat >> $apparmor_file_path <<EOF
    $TMPFS_DIR/ r,
    $TMPFS_DIR/** rwk,
EOF
    sudo /etc/init.d/apparmor restart
  fi
}
