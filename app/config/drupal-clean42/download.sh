#!/bin/bash

## download.sh -- Download Drupal and CiviCRM

###############################################################################

git_cache_setup "https://github.com/CiviCRM42/civicrm42-core.git" "$CACHE_DIR/CiviCRM42/civicrm42-core.git"
git_cache_setup "https://github.com/CiviCRM42/civicrm42-drupal.git" "$CACHE_DIR/CiviCRM42/civicrm42-drupal.git"
git_cache_setup "https://github.com/CiviCRM42/civicrm42-packages.git" "$CACHE_DIR/CiviCRM42/civicrm42-packages.git"

## Force version 4.2
CIVI_VERSION=4.2
[ -z "$CMS_VERSION" ] && CMS_VERSION=7
MAKEFILE="${TMPDIR}/${SITE_TYPE}/${SITE_NAME}/${SITE_ID}.make"
cvutil_makeparent "$MAKEFILE"
cat "$SITE_CONFIG_DIR/drush.make.tmpl" \
  | sed "s;%%CACHE_DIR%%;${CACHE_DIR};" \
  | sed "s;%%CIVI_VERSION%%;${CIVI_VERSION};" \
  | sed "s;%%CMS_VERSION%%;${CMS_VERSION};" \
  > "$MAKEFILE"

drush -y make --working-copy "$MAKEFILE" "$WEB_ROOT"
