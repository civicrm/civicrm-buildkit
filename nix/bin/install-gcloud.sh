#!/bin/bash

# This installs each of the bknix profiles in a way that's useful for the CI servers.
# Specifically, for each profile:
#   - Install the binaries in /nix/var/nix/profiles/bknix-$PROFILE
#   - Initialize a data folder in /home/$OWNER/bknix-$PROFILE
#   - Register each service from `.loco/jenkins-*.yml` and `.loco/publisher-*.yml` in systemd
#
# Pre-requisites:
#   Use a Debian-like main OS
#   Install the "nix" package manager.
#   Only tested with multiuser mode.
#   Login as proper root (e.g. `sudo -i bash`)
#
# Example: Install (or upgrade) all the profiles
#   ./bin/install-gcloud.sh
#
# Example: Install (or upgrade) all the profiles, overwriting any local config files
#   FORCE_INIT=-f ./bin/install-gcloud.sh
#
# Example:
#   NO_SYSTEMD=1 ./bin/install-gcloud.sh
#
# After installation, an automated script can use a statement like:
#    eval $(use-bknix min)
#    eval $(use-bknix max)
#    eval $(use-bknix dfl)

###########################################################
## Main

set -e
BINDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source "$BINDIR/../lib/common.sh"

check_reqs
install_warmup
init_folder $PWD/examples/gcloud-bknix-ci /etc/bknix-ci
install_bin bin/use-bknix.arrbuk /usr/local/bin/use-bknix
install_all_jenkins
install_all_publisher
