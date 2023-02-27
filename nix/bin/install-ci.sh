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
# Tip: The default list of active profiles for CI is "dfl min max" (jenkins).
# To enable "old" or "edge" profiles (or "publisher" user), customize:
#  - /etc/bknix-ci/install_all_jenkins.sh
#  - /etc/bknix-ci/install_all_publisher.sh
#
# Example: Install (or upgrade) all the profiles
#   ./bin/install-ci.sh
#
# Example: Install (or upgrade) all the profiles, overwriting any local config files
#   FORCE_INIT=-f ./bin/install-ci.sh
#
# Example:
#   NO_SYSTEMD=1 ./bin/install-ci.sh
#
# After installation, an automated script can use a statement like:
#    eval $(use-bknix min)
#    eval $(use-bknix max)
#    eval $(use-bknix dfl)

###########################################################
## Bootstrap

set -e
BINDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
BKNIXSRC=$(dirname "$BINDIR")
cd "$BKNIXSRC"
source "$BINDIR/../lib/common.sh"

###########################################################
## Main

if [ -z "$1" -o ! -d "$BKNIXSRC/examples/$1" ]; then
  echo "usage: ./bin/install-ci.sh <template-name>"
  echo "The <template-name> should correspond to a folder in examples/"
  exit 1
else
  BKNIX_CI_TEMPLATE="$1"
fi

assert_root_user
check_reqs
install_cachix
init_folder "$BKNIXSRC/examples/$BKNIX_CI_TEMPLATE" /etc/bknix-ci
install_bin "$BINDIR"/use-bknix /usr/local/bin/use-bknix
install_bin "$BINDIR"/await-bknix /usr/local/bin/await-bknix
install_bin "$BINDIR"/run-bknix-job /usr/local/bin/run-bknix-job
install_all_jenkins
install_all_publisher
