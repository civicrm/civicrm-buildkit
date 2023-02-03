#!/bin/bash

## This is an example of how to setup /etc/bknix-ci/install_all_publisher.sh
## for an ephmeral taskr-running node.
##
## It defines very high-level options for installing profiles for user "publisher".

RAMDISKSIZE=250M
PROFILES="min"

## Services are started transactionally
NO_SYSTEMD=1
SYSTEMD_ENABLE="no"
SYSTEMD_START="no"
