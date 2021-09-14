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

## Clear out any cached container files to avoid it attempting to load
## the cached monolog service before the extension is installed.
rm -f ${WEB_ROOT}/drupal/sites/default/files/civicrm/templates_c/*.php

## Set site key if requested in Docker environment
[ ! -z "$FR_DOCKER_CIVI_SITE_KEY" ] && CIVI_SITE_KEY=${FR_DOCKER_CIVI_SITE_KEY}

civicrm_install

## Comment out for now
"${WEB_ROOT}/drupal/sites/default/civicrm/extensions/rpow/bin/harvey-dent" --root "${WEB_ROOT}/drupal"
echo "DROP DATABASE IF EXISTS fredge"| amp sql -N civi -a
echo "CREATE DATABASE IF NOT EXISTS fredge"| amp sql -N civi -a
eval mysql $CIVI_DB_ARGS <<EOSQL
  GRANT ALL PRIVILEGES ON fredge.* TO $CMS_DB_USER@'%';
EOSQL

###############################################################################
## Extra configuration
pushd "$CMS_ROOT"
drush -y en civicrm
cv en --ignore-missing search_kit wmf-civicrm

drush -y en --debug `cat sites/default/enabled_modules`

drush -y -v --debug updatedb

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

## Add a contact record for the admin user so we can do stuff with it before logging in
drush -y civicrm-sync-users-contacts

[ ! -z "$FR_DOCKER_CIVI_API_KEY" ] && cv api4 Contact.update \
	'{"where":[["display_name","=","admin@example.com"]],"values":{"api_key":"'$FR_DOCKER_CIVI_API_KEY'"}}'

echo "adding general wmf dev-specific settings"
DEV_SETTINGS_FILE="${WEB_ROOT}/drupal/sites/default/wmf_settings_developer.json"
if [ -e "$DEV_SETTINGS_FILE" ]; then
  drush --in=json cvapi Setting.create < "$DEV_SETTINGS_FILE"
fi

echo "adding general wmf settings"
WMF_SETTINGS_FILE="${WEB_ROOT}/drupal/sites/default/wmf_settings.json"
if [ -e "$WMF_SETTINGS_FILE" ]; then
  drush --in=json cvapi Setting.create debug=1 < "$WMF_SETTINGS_FILE"
fi

echo "adding anonymous user"
drush cvapi Contact.create first_name='Anonymous' last_name=Anonymous email=fakeemail@wikimedia.org contact_type=Individual

echo "adding wmf roles"
WMF_ROLES_FILE="${WEB_ROOT}/drupal/sites/default/wmf_roles/roles.txt"
if [ -e "$WMF_ROLES_FILE" ]; then
  while IFS= read -r role; do
    # we want to declare administrator permissions but the role exists.
    if [ "$role" != 'administrator' ] && [ "$role" != 'authenticated user' ] && [ "$role" != 'anonymous' ]; then
      echo "Adding role $role"
      drush -y role-create "$role"
    fi
    WMF_ROLE_FILE="${WEB_ROOT}/drupal/sites/default/wmf_roles/${role}.txt"
    if [ -e "$WMF_ROLE_FILE" ]; then
      echo "Adding permissions for ${role}"
      drush scr "$PRJDIR/src/drush/perm.php" < "$WMF_ROLE_FILE"
    fi
  done < "$WMF_ROLES_FILE"
fi
drush user-create engage --mail="engage@example.com" --password="engage"
drush -y user-add-role fr-tech "$ADMIN_USER"
drush -y user-add-role "Engage Direct Mail" "engage"
