#!/bin/bash

###########################################################
## Bootstrap

set -e
BINDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
BKNIXSRC=$(dirname "$BINDIR")
cd "$BKNIXSRC"
source "$BINDIR/../lib/common.sh"

###########################################################
## Main

if [ -z "$CACHIX_SIGNING_KEY" ]; then
  echo "Please set CACHIX_SIGNING_KEY before running" 1>&2
  exit 1
fi

## These are three ways to ask for list of packages to publish.
## It's not entirely clear if we need all 3, or perhaps just 2 of them, but I don't any one on its own is enough.

nix-build -E 'let p=import ./profiles; in builtins.attrValues p' | sort -u | cachix push bknix
nix-instantiate default.nix | sort -u | cachix push bknix
nix-store -r $( ( for PRF in old min dfl max edge; do nix-instantiate -A profiles.$PRF default.nix ; done ) | sort -u ) | cachix push bknix