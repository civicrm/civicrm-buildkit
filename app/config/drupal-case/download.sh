#!/usr/bin/env bash

## download.sh -- Download Drupal and CiviCRM

###############################################################################

git_cache_setup_id civicrm/civicrm-core civicrm/civicrm-packages civicrm/civicrm-drupal
git_cache_setup_id civicrm/api4
git_cache_setup_id civicrm/org.civicrm.shoreditch
git_cache_setup_id civicrm/org.civicrm.styleguide
git_cache_setup_id civicrm/org.civicrm.civicase

###############################################################################

[ -z "$CMS_VERSION" ] && CMS_VERSION=7

MAKEFILE="${TMPDIR}/${SITE_TYPE}/${SITE_NAME}/${SITE_ID}.make"
cvutil_makeparent "$MAKEFILE"
cat "$SITE_CONFIG_DIR/drush.make.tmpl" \
  | sed "s;%%CACHE_DIR%%;${CACHE_DIR};" \
  | sed "s;%%CIVI_VERSION%%;${CIVI_VERSION};" \
  | sed "s;%%CMS_VERSION%%;${CMS_VERSION};" \
  > "$MAKEFILE"

drush -y make --working-copy "$MAKEFILE" "$WEB_ROOT/web"
