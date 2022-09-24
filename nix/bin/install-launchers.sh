#!/bin/bash

## Install desktop launchers

###########################################################
## Bootstrap

set -e
BINDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
BKNIXSRC=$(dirname "$BINDIR")
BUILDKIT=$(dirname "$BKNIXSRC")
cd "$BKNIXSRC"
source "$BINDIR/../lib/common.sh"

###########################################################
##

if [ -z `which xfce4-terminal` ]; then
  echo "Error: Only XFCE4 is currently supported"
  exit 1
else
  install_xfce4_launchers
fi
