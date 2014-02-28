#!/bin/bash

## download.sh -- Download Drupal and CiviCRM

###############################################################################

if [ "$CIVI_VERSION" != "master" ]; then
  echo "WARNING: This configuration is hardcoded to work with master."
fi

[ -z "$CMS_VERSION" ] && CMS_VERSION=7.x
MAKEFILE="${TMPDIR}/${SITE_TYPE}.make"
cat "$SITE_CONFIG_DIR/drush.make.tmpl" \
  | sed "s;%%CACHE_DIR%%;${CACHE_DIR};" \
  | sed "s;%%CIVI_VERSION%%;${CIVI_VERSION};" \
  | sed "s;%%CMS_VERSION%%;${CMS_VERSION};" \
  > "$MAKEFILE"

drush -y make --working-copy "$MAKEFILE" "$WEB_ROOT"

pushd "$WEB_ROOT/sites/all/modules/civicrm" >> /dev/null
  composer install
popd >> /dev/null