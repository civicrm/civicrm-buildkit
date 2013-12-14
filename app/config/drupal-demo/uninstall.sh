#!/bin/bash

if [ -f "$CIVI_SETTINGS" ]; then
  rm -f "$CIVI_SETTINGS"
fi

drupal_singlesite_uninstall

## Disabled to provide continuity during rebuilds
## Maybe we should a destroy function that preserves the old metadata?
#amp destroy --root="$WEB_ROOT" --name=cms
#amp destroy --root="$WEB_ROOT" --name=civi
