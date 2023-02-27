#!/bin/bash

###########################################################
## Bootstrap

BINDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
BKNIXSRC=$(dirname "$BINDIR")
cd "$BKNIXSRC"
source "$BINDIR/../lib/common.sh"

###########################################################
## Main
assert_root_user

for OWNER in jenkins publisher ; do
  if [ -e "/etc/bknix-ci/worker-n" ]; then
    if [ -d "/home/$OWNER/bknix" ]; then
      echo "Update \"bknix\" for user \"$OWNER\""
      su - $OWNER -c 'eval $(use-bknix min -N0) && cd $LOCO_PRJ && git checkout -- package-lock.json && git pull && ./bin/civi-download-tools'
    fi
  fi

  for PROF in dfl min max old edge ; do
    if [ -d "/home/$OWNER/bknix-$PROF" ]; then
      echo "Update \"bknix-$PROF\" for user \"$OWNER\""
      su - $OWNER -c 'eval $(use-bknix '$PROF') && cd $LOCO_PRJ && git checkout -- package-lock.json && git pull && ./bin/civi-download-tools'
    fi
  done
done
