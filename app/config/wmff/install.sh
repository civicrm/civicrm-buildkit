#!/bin/bash

## install.sh -- Create config files and databases; fill the databases

## Drupal is actually in a subdir of the main source tree
CMS_ROOT="$WEB_ROOT/drupal"

# Update vendor libraries.
pushd "$WEB_ROOT"
composer install
popd

###############################################################################
## Create virtual-host and databases

amp_install

###############################################################################
## Setup Drupal (config files, database tables)

drupal_install

###############################################################################
## Setup CiviCRM (config files, database tables)

CIVI_DOMAIN_NAME="Demonstrators Anonymous"
CIVI_DOMAIN_EMAIL="\"Demonstrators Anonymous\" <info@example.org>"
CIVI_CORE="${CMS_ROOT}/sites/all/modules/civicrm"
CIVI_SETTINGS="${CMS_ROOT}/sites/default/civicrm.settings.php"
CIVI_FILES="${CMS_ROOT}/sites/default/files/civicrm"
CIVI_TEMPLATEC="${CIVI_FILES}/templates_c"
CIVI_UF="Drupal"
CIVI_EXT_DIR="${CMS_ROOT}/sites/default/civicrm/extensions"
CIVI_EXT_URL="${CMS_URL}/sites/default/civicrm/extensions"

civicrm_install

## Comment out for now
##"${WEB_ROOT}/sites/default/civicrm/extensions/rpow/bin/harvey-dent" --root "${WEB_ROOT}/drupal"

echo "CREATE DATABASE IF NOT EXISTS fredge"| amp sql -N civi -a
echo "GRANT ALL ON fredge.* TO 'drupal'@'%'"| amp sql -N civi -a
###############################################################################
## Extra configuration
pushd "$CMS_ROOT"
drush -y en `cat sites/default/enabled_modules`

drush -y updatedb

## Setup theme
drush -y en tivy
drush vset theme_default tivy
drush -y dis overlay
export SITE_CONFIG_DIR
drush -y -u "$ADMIN_USER" scr "$SITE_CONFIG_DIR/install-theme.php"

## Based on the block info, CRM_Core_Block::CREATE_NEW and CRM_Core_Block::ADD should be enabled by default, but they aren't.
## "drush -y cc all" and "drush -y cc block" do *NOT* solve the problem. But this does:
drush php-eval -u "$ADMIN_USER" 'module_load_include("inc","block","block.admin"); block_admin_display();'

## Setup demo user
drush -y user-create --password="$DEMO_PASS" --mail="$DEMO_EMAIL" "$DEMO_USER"

DEV_SETTINGS_FILE="${WEB_ROOT}/sites/default/wmf_settings_developer.json"
if [ -e "$DEV_SETTINGS_FILE" ]; then
  drush --in=json cvapi Setting.create < "$DEV_SETTINGS_FILE"
fi

WMF_SETTINGS_FILE="${WEB_ROOT}/sites/default/wmf_settings.json"
if [ -e "$WMF_SETTINGS_FILE" ]; then
  drush --in=json cvapi Setting.create < "$WMF_SETTINGS_FILE"
fi

#drush -y user-add-role civicrm_webtest_user "$DEMO_USER"
# In Garland, CiviCRM's toolbar looks messy unless you also activate Drupal's "toolbar", so grant "access toolbar"
# We've activated more components than typical web-test baseline, so grant rights to those components.
#for perm in 'access toolbar'
#do
#  drush -y role-add-perm civicrm_webtest_user "$perm"
#done
popd
