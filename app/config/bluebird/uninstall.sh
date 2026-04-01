#!/usr/bin/env bash

## uninstall.sh -- Delete config files and databases

###############################################################################

if [ -f "$CIVI_SETTINGS" ]; then
  chmod u+w $(dirname "$CIVI_SETTINGS")
  rm -f "$CIVI_SETTINGS"
fi

if [ -d "$WEB_ROOT" ]; then
  pushd "$WEB_ROOT" >> /dev/null
    for p in bluebird.cfg local/data local/import ; do
      if [ -d "$p" ]; then rm -rf "$p" ; fi
    done
  popd >> /dev/null
fi

#drupal_uninstall
amp_uninstall