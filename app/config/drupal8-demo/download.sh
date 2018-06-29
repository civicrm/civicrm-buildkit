#!/bin/bash

## download.sh -- Download Drupal and CiviCRM

###############################################################################

[ -z "$CMS_VERSION" ] && CMS_VERSION=8.x
[ -z "$VOL_VERSION" ] && VOL_VERSION='master'
[ -z "$NG_PRFL_VERSION" ] && NG_PRFL_VERSION='master'
[ -z "$DISC_VERSION" ] && DISC_VERSION=master

MAKEFILE="${TMPDIR}/${SITE_TYPE}/${SITE_NAME}/${SITE_ID}.make"
cvutil_makeparent "$MAKEFILE"
cat "$SITE_CONFIG_DIR/drush.make.tmpl" \
  | sed "s;%%CACHE_DIR%%;${CACHE_DIR};" \
  | sed "s;%%CIVI_VERSION%%;${CIVI_VERSION};" \
  | sed "s;%%CMS_VERSION%%;${CMS_VERSION};" \
  | sed "s;%%DISC_VERSION%%;${DISC_VERSION};" \
  | sed "s;%%VOL_VERSION%%;${VOL_VERSION};" \
  | sed "s;%%NG_PRFL_VERSION%%;${NG_PRFL_VERSION};" \
  > "$MAKEFILE"

drush8 -y make --working-copy "$MAKEFILE" "$WEB_ROOT"
