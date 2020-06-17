#!/bin/bash
for OWNER in jenkins publisher ; do
  for PROF in dfl min max old edge ; do
    if [ -d "/home/$OWNER/bknix-$PROF" ]; then
      echo "Update \"$PROF\" for user \"$OWNER\""
      su - $OWNER -c 'eval $(use-bknix '$PROF') && bknix update'
    fi
  done
done