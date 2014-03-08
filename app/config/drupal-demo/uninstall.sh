#!/bin/bash

## uninstall.sh -- Delete config files and databases

###############################################################################

if [ -f "$CIVI_SETTINGS" ]; then
  chmod u+w $(dirname "$CIVI_SETTINGS")
  rm -f "$CIVI_SETTINGS"
fi

drupal_uninstall

## Disabled to provide continuity during rebuilds
## Maybe we should a destroy function that preserves the old metadata?
#amp destroy --root="$WEB_ROOT" --name=cms
#amp destroy --root="$WEB_ROOT" --name=civi
