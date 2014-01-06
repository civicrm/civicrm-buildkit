#!/bin/bash

## download.sh -- Download Drupal and CiviCRM

###############################################################################

set +x
if [ ! -d "$SITE_CONFIG_DIR/civicrm_starterkit" ]; then
  echo "----------------------------------------------------------------------------------------------------"
  echo "[[ civicrm_starterkit: Clone repository to $SITE_CONFIG_DIR/civicrm_starterkit ]]"
  git clone "http://git.drupal.org/project/civicrm_starterkit.git" "$SITE_CONFIG_DIR/civicrm_starterkit"
else
  echo "[[ civicrm_starterkit: Use existing clone. You may want to manually update for the latest changes. ]]"
  echo "----------------------------------------------------------------------------------------------------"
fi
set -x

MAKEFILE="$SITE_CONFIG_DIR/civicrm_starterkit/build-local-civicrm_starterkit.make"
drush -y make --working-copy "$MAKEFILE" "$WEB_ROOT"

## Work-around: starterkit doesn't have settings template
cp "$SITE_CONFIG_DIR/civicrm.settings.php.template" "$WEB_ROOT/profiles/civicrm_starterkit/modules/civicrm/templates/CRM/common/civicrm.settings.php.template"
