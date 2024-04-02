#!/usr/bin/env bash

## uninstall.sh -- Delete config files and databases

for file in duderino.sqlite3 cache.sqlite3 ; do
  if [ -e "$WEB_ROOT/data/$file" ]; then
    rm -f "$WEB_ROOT/data/$file"
  fi
done

amp_uninstall
