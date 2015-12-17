#!/bin/bash

## uninstall.sh -- Delete config files and databases

###############################################################################

if [ -f "$CIVI_SETTINGS" ]; then
  rm -f "$CIVI_SETTINGS"
fi

backdrop_uninstall
amp_uninstall
