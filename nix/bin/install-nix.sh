#!/bin/bash
##
## This is a small wrapper for the normal installer. It displays a prompt to ask about common CLI options,
## and it configures 'cachix'.

###########################################################
## Bootstrap

set -e
BINDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
BKNIXSRC=$(dirname "$BINDIR")
cd "$BKNIXSRC"
source "$BINDIR/../lib/common.sh"

###########################################################
## Main

echo "[install-nix.sh] Starting"

assert_not_root_user
install_nix_interactive
check_reqs
install_cachix

echo
echo "TIP: You may need to restart the console or session to gain full access to nix commands."

echo "[install-nix.sh] Finished"
