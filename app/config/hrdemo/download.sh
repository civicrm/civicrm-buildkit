#!/bin/bash

## download.sh -- Download Drupal and CiviCRM

###############################################################################

git_cache_setup "https://github.com/civicrm/civihr.git" "$CACHE_DIR/civicrm/civihr.git"

[ -z "$CMS_VERSION" ] && CMS_VERSION=7.x
[ -z "$CIVI_VERSION" ] && CIVI_VERSION=4.4
[ -z "$HR_VERSION" ] && HR_VERSION=master

MAKEFILE="${TMPDIR}/${SITE_TYPE}.make"
cat "$SITE_CONFIG_DIR/drush.make.tmpl" \
  | sed "s;%%CACHE_DIR%%;${CACHE_DIR};" \
  | sed "s;%%CIVI_VERSION%%;${CIVI_VERSION};" \
  | sed "s;%%CMS_VERSION%%;${CMS_VERSION};" \
  | sed "s;%%HR_VERSION%%;${HR_VERSION};" \
  > "$MAKEFILE"

drush -y make --working-copy "$MAKEFILE" "$WEB_ROOT"
