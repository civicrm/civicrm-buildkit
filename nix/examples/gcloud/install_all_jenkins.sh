#!/bin/bash

## This is an example of how to setup /etc/bknix-ci/install_all_jenkins.sh
## for an ephemeral/dev-oriented gcloud VM.
##
## It defines very high-level options for installing profiles for user "jenkins",
## changing defaults for `HTTPD_DOMAIN`, `PROFILES`, etc.

## This ramdisk is smaller than usual because we use pre-emptible instances that don't retain data as long.
RAMDISKSIZE=4G
HTTPD_DOMAIN=$(curl 'http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip' -H "Metadata-Flavor: Google").nip.io
PROFILES="dfl min max edge"

## There is a startup script (via https://cloud.google.com/compute/docs/instances/startup-scripts/) which calls
## `reset-ci.sh` (shutdown+upgrade+start all services). "Enabling" services (auto-start via systemd) just adds
## noise and makes it hard to detect the final startup.
SYSTEMD_ENABLE="no"
SYSTEMD_START="yes"
