#!/bin/bash

## download.sh -- Download Drupal and CiviCRM

###############################################################################

git_cache_setup "https://github.com/civicrm/civivolunteer.git" "$CACHE_DIR/civicrm/civivolunteer.git"
git_cache_setup "https://github.com/TechToThePeople/civisualize.git" "$CACHE_DIR/TechToThePeople/civisualize.git"
git_cache_setup "https://github.com/dlobo/org.civicrm.module.cividiscount.git" "$CACHE_DIR/dlobo/org.civicrm.module.cividiscount.git"

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
