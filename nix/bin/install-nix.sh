#!/bin/bash
##
## This is a small wrapper for the normal installer. It displays a prompt to ask about common CLI options.

set -e
BINDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source "$BINDIR/../lib/common.sh"

install_nix_interactive
