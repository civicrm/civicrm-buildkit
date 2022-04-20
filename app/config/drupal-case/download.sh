#!/bin/bash

## download.sh -- Download Drupal and CiviCRM

###############################################################################

git_cache_setup "https://github.com/civicrm/org.civicrm.shoreditch.git" "$CACHE_DIR/civicrm/org.civicrm.shoreditch.git"
git_cache_setup "https://github.com/civicrm/org.civicrm.styleguide.git" "$CACHE_DIR/civicrm/org.civicrm.styleguide.git"
git_cache_setup "https://github.com/civicrm/org.civicrm.civicase.git" "$CACHE_DIR/civicrm/org.civicrm.civicase.git"

[ -z "$CMS_VERSION" ] && CMS_VERSION=7

MAKEFILE="${TMPDIR}/${SITE_TYPE}/${SITE_NAME}/${SITE_ID}.make"
cvutil_makeparent "$MAKEFILE"
cat "$SITE_CONFIG_DIR/drush.make.tmpl" \
  | sed "s;%%CACHE_DIR%%;${CACHE_DIR};" \
  | sed "s;%%CIVI_VERSION%%;${CIVI_VERSION};" \
  | sed "s;%%CMS_VERSION%%;${CMS_VERSION};" \
  > "$MAKEFILE"

drush -y make --working-copy "$MAKEFILE" "$WEB_ROOT/web"
