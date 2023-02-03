#!/bin/bash

## This is an example of how to setup /etc/bknix-ci/install_all_jenkins.sh
## for an ephmeral taskr-running node.
##
## It defines very high-level options for installing profiles for user "jenkins".

RAMDISKSIZE=3G
PROFILES="dfl min max edge"

## Services are started transactionally
NO_SYSTEMD=1
SYSTEMD_ENABLE="no"
SYSTEMD_START="no"
