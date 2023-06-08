#!/bin/bash

## uninstall.sh -- Delete config files and databases

###############################################################################

if [ -f "$CIVI_SETTINGS" ]; then
  chmod u+w $(dirname "$CIVI_SETTINGS")
  rm -f "$CIVI_SETTINGS"
fi

drupal8_uninstall
amp_uninstall
