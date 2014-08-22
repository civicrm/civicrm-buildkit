#!/bin/bash

## download.sh -- Download Drupal and CiviCRM

###############################################################################

git_cache_setup "https://github.com/civicrm/civivolunteer.git" "$CACHE_DIR/civicrm/civivolunteer.git"

[ -z "$CMS_VERSION" ] && CMS_VERSION=7.x
[ -z "$VOL_VERSION" ] && VOL_VERSION='4.4-1.x'

MAKEFILE="${TMPDIR}/${SITE_TYPE}/${SITE_NAME}/${SITE_ID}.make"
cvutil_makeparent "$MAKEFILE"
cat "$SITE_CONFIG_DIR/drush.make.tmpl" \
  | sed "s;%%CACHE_DIR%%;${CACHE_DIR};" \
  | sed "s;%%CIVI_VERSION%%;${CIVI_VERSION};" \
  | sed "s;%%CMS_VERSION%%;${CMS_VERSION};" \
  | sed "s;%%VOL_VERSION%%;${VOL_VERSION};" \
  > "$MAKEFILE"

drush -y make --working-copy "$MAKEFILE" "$WEB_ROOT"

svn_cache_clone "$CACHE_DIR/civicrm/l10n-trunk.svn" "$WEB_ROOT/sites/all/modules/civicrm/l10n"
