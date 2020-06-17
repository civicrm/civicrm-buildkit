#!/bin/bash

set -e

if [ ! -d "/root/bknix" ]; then
  echo "Cannot run: failed to find master folder /root/bknix"
  exit 1
fi
cd /root/bknix

source /etc/profile

echo "Updating configuration"
git pull --ff-only

echo "Reinstalling profiles"
NO_SYSTEMD=1 FORCE_INIT=-f ./bin/install-gcloud.sh

echo "Updating buildkit"
./bin/update-ci-buildkit.sh
