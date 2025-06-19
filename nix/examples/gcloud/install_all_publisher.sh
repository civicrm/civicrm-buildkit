#!/usr/bin/env bash

## This is an example of how to setup /etc/bknix-ci/install_all_publisher.sh
## for an ephemeral/dev-oriented gcloud VM.
##
## It defines very high-level options for installing profiles for user "publisher".

RAMDISKSIZE=250M
HTTPD_DOMAIN=$(curl 'http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip' -H "Metadata-Flavor: Google" | sed 's;\.;-;g').ip.civi.bid
PROFILES="min"

## There is a startup script (via https://cloud.google.com/compute/docs/instances/startup-scripts/) which calls
## `reset-ci.sh` (shutdown+upgrade+start all services). "Enabling" services (auto-start via systemd) just adds
## noise and makes it hard to detect the final startup.
SYSTEMD_ENABLE="no"
SYSTEMD_START="yes"
