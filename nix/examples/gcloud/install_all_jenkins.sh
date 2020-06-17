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
