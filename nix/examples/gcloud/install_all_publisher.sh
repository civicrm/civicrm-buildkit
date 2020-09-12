#!/bin/bash

## This is an example of how to setup /etc/bknix-ci/install_all_publisher.sh
## for an ephemeral/dev-oriented gcloud VM.
##
## It defines very high-level options for installing profiles for user "publisher".

RAMDISKSIZE=250M
HTTPD_DOMAIN=$(curl 'http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip' -H "Metadata-Flavor: Google").nip.io
PROFILES="min"
