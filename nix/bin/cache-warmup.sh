#!/usr/bin/env bash
for OWNER in jenkins publisher ; do
  for PROF in dfl min max alt old edge ; do
    if [ -d "/home/$OWNER/bknix-$PROF" ]; then
      echo "Update \"$PROF\" for user \"$OWNER\""
      su - $OWNER -c 'eval $(use-bknix '$PROF') && civibuild cache-warmup'
    fi
  done
done