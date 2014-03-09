#!/bin/bash

## uninstall.sh -- Delete config files and databases

###############################################################################

if [ -f "$CIVI_SETTINGS" ]; then
  rm -f "$CIVI_SETTINGS"
fi

drupal_uninstall
amp_uninstall