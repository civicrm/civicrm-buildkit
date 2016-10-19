#!/bin/bash

## install.sh -- Create config files and databases; fill the databases

##
# Creates the default CiviHR users
function create_default_users() {
  drush -y user-create --password="civihr_staff" --mail="civihr_staff@compucorp.co.uk" "civihr_staff"
  drush -y user-add-role civihr_staff "civihr_staff"

  drush -y user-create --password="civihr_manager" --mail="civihr_manager@compucorp.co.uk" "civihr_manager"
  drush -y user-add-role civihr_manager "civihr_manager"

  drush -y user-create --password="civihr_admin" --mail="civihr_admin@compucorp.co.uk" "civihr_admin"
  drush -y user-add-role civihr_admin "civihr_admin"
}

##
# Creates the "Personal" Location Type
function create_personal_location_type() {
  drush cvapi LocationType.create sequential=1 name="Personal" display_name="Personal" vcard_name="PERSONAL" description="Place of Residence"
}

##
# Deletes the "Name and address profile"
function delete_name_and_address_profile() {
  PROFILE_ID=`[[ $(drush cvapi UFGroup.getsingle return="id" title="Name and address") =~ \[id\].+([1-9]) ]] && echo ${BASH_REMATCH[1]}`

  drush cvapi UFGroup.delete sequential=1 id=$PROFILE_ID
}

##
# Disables the unused drupal blocks, leaving only the "main content" one active
function disabled_unused_blocks() {
  for block in 'navigation' 'form' 'powered-by' 'help' 'navigation' 'login' \
    '2' '3' '5' '7'
  do
    drush block-disable --delta="$block"
  done
}

##
# Installs CiviHR extensions
function install_civihr() {
  ## (no sample data as default)
  bash ${CIVI_CORE}/tools/extensions/civihr/bin/drush-install.sh ${CIVI_CORE}

  ## (with sample data - if required)
  # bash ${CIVI_CORE}/tools/extensions/civihr/bin/drush-install.sh --with-sample-data
}

##
# Sets up the themes
function setup_themes {
  ## Drupal theme
  drush -y en civihr_default_theme
  drush -y vset theme_default civihr_default_theme

  ## Civicrm and admin theme
  drush -y vset admin_theme seven
  drush -y vset civicrmtheme_theme_admin seven
  drush -y vset civicrmtheme_theme_public seven
}

###############################################################################
## Create virtual-host and databases

amp_install

###############################################################################
## Grant access for the Drupal database user to access the Civi Database too

eval mysql $CIVI_DB_ARGS <<EOSQL
  GRANT ALL PRIVILEGES ON $CIVI_DB_NAME.* TO $CMS_DB_USER@'%';
EOSQL

###############################################################################
## Setup Drupal (config files, database tables)

drupal_install

###############################################################################
## Setup CiviCRM (config files, database tables)

DRUPAL_SITE_DIR=$(_drupal_multisite_dir "$CMS_URL" "$SITE_ID")
CIVI_DOMAIN_NAME="Demonstrators Anonymous"
CIVI_DOMAIN_EMAIL="\"Demonstrators Anonymous\" <info@example.org>"
CIVI_CORE="${WEB_ROOT}/sites/all/modules/civicrm"
CIVI_SETTINGS="${WEB_ROOT}/sites/${DRUPAL_SITE_DIR}/civicrm.settings.php"
CIVI_FILES="${WEB_ROOT}/sites/${DRUPAL_SITE_DIR}/files/civicrm"
CIVI_TEMPLATEC="${CIVI_FILES}/templates_c"
CIVI_UF="Drupal"

## civicrm-core v4.7+ sets default ext dir; for older versions, we'll set our own.
if [[ "$CIVI_VERSION" =~ ^4.[0123456](\.([0-9]|alpha|beta)+)?$ ]] ; then
  CIVI_EXT_DIR="${WEB_ROOT}/sites/${DRUPAL_SITE_DIR}/ext"
  CIVI_EXT_URL="${CMS_URL}/sites/${DRUPAL_SITE_DIR}/ext"
fi

civicrm_install

###############################################################################
## Extra configuration
pushd "${WEB_ROOT}/sites/${DRUPAL_SITE_DIR}" >> /dev/null

  drush -y dl drush_extras drush_taxonomyinfo

  drush -y updatedb
  drush -y dis overlay shortcut color
  drush -y en administerusersbyrole role_delegation subpermissions civicrm toolbar locale seven userprotect

  ## Setup welcome page
  drush -y scr "$SITE_CONFIG_DIR/install-welcome.php"

  install_civihr

  drush -y en civicrmtheme civihr_employee_portal_features civihr_default_permissions username_to_external_id

  setup_themes
  create_default_users
  disabled_unused_blocks
  create_personal_location_type
  delete_name_and_address_profile

  ## Create My Details and My Emergency Contact forms
  drush refresh-node-export-files

  ## Clear the cache
  drush cc all
popd >> /dev/null
