#!/bin/bash
set -e

set -e
BINDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source "$BINDIR/../lib/common.sh"

check_reqs
install_warmup
install_bin bin/use-bknix.arrbuk /usr/local/bin/use-bknix

PROFILES=min
install_all_jenkins

#install_buildkit jenkins dfl
#install_buildkit jenkins min
#install_buildkit jenkins max
#install_buildkit jenkins old
#install_buildkit jenkins edge

#install_buildkit publisher min
#install_buildkit publisher max
#nstall_buildkit publisher old