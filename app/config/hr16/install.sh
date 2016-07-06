#!/bin/bash

## install.sh -- Create config files and databases; fill the databases

##
# Grants the given permission only to the admin roles (admin, civihr_admin)
function admin_only_permission_for() {
  for user_role in 'administrator' 'civihr_admin'; do
    drush -y role-add-perm "$user_role" "$1"
  done

  for user_role in 'anonymous user' 'authenticated user' 'civihr_staff' \
    'civihr_manager'
  do
    drush -y role-remove-perm "$user_role" "$1"
  done
}

##
# Grants the given permission for the admin and the civi users
function admin_and_civi_users_permission_for() {
  for user_role in 'administrator' 'civihr_staff' 'civihr_manager' 'civihr_admin'
  do
    drush -y role-add-perm "$user_role" "$1"
  done
}

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
  bash ${CIVI_CORE}/tools/extensions/civihr/bin/drush-install.sh

  ## (with sample data - if required)
  # bash ${CIVI_CORE}/tools/extensions/civihr/bin/drush-install.sh --with-sample-data

  ## Disable / Uninstall old extensions (temporary should be removed when we don't need the old HRjob anymore)
  drush cvapi extension.disable keys=org.civicrm.hrjob
}

##
# Denies the given permission to all roles
function no_permission_for() {
  for user_role in 'anonymous user' 'authenticated user' 'administrator' \
    'civihr_staff' 'civihr_manager' 'civihr_admin'
  do
    drush -y role-remove-perm "$user_role" "$1"
  done
}

##
# Gives the "edit" and "cancel" user permission to admin users for
# every "civihr_" users and for users with no roles
function set_edit_and_cancel_user_permissions() {
  IDS=$(drush rls --fields=rid | awk '{if(NR>1)print}')

  printf '%s\n' "$IDS" | while read line ; do
    if [[ $line -gt 10 ]] || [[ $line == 2 ]] ; then
        admin_only_permission_for "edit users with role $line"
        admin_only_permission_for "cancel users with role $line"
    fi
  done
}

##
# Gives the "Edit terms" and "Delete terms" for the "HR Resource type"
# to admin users
function set_hr_document_type_permissions() {
  TAXONOMY_TERMS=$(drush tvl)

  printf '%s\n' "$TAXONOMY_TERMS" | while read line ; do
    if echo $line | grep -q "hr_resource_type"; then
      HR_DOCUMENT_TYPE_ID=$(echo $line |cut -d' ' -f1)

      admin_only_permission_for "edit terms in $HR_DOCUMENT_TYPE_ID"
      admin_only_permission_for "delete terms in $HR_DOCUMENT_TYPE_ID"
    fi
  done
}

##
# Set the drupal permissions
function set_permissions() {
  # In Drupal, CiviCRM's toolbar looks messy unless you also activate Drupal's "toolbar", so we grant "access toolbar".
  admin_only_permission_for 'access toolbar'

  admin_only_permission_for 'access CiviCRM'
  admin_only_permission_for 'view the administration theme'
  admin_only_permission_for 'create users'
  admin_only_permission_for 'access users overview'
  admin_only_permission_for 'assign civihr_admin role'
  admin_only_permission_for 'assign civihr_staff role'
  admin_only_permission_for 'assign civihr_manager role'
  admin_only_permission_for 'create hr_documents content'
  admin_only_permission_for 'access content overview'
  admin_only_permission_for 'edit own hr_documents content'
  admin_only_permission_for 'edit any hr_documents content'
  admin_only_permission_for 'delete own hr_documents content'
  admin_only_permission_for 'delete any hr_documents content'

  admin_and_civi_users_permission_for 'change own password'

  no_permission_for 'view my contact'
  no_permission_for 'access Contact Dashboard'

  set_edit_and_cancel_user_permissions
  set_hr_document_type_permissions
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
  drush -y en administerusersbyrole role_delegation subpermissions civicrm toolbar locale seven login_destination userprotect

  ## Setup welcome page
  drush -y scr "$SITE_CONFIG_DIR/install-welcome.php"

  ## Setup login_destination
  #above# drush -y en login_destination
  drush -y scr "$SITE_CONFIG_DIR/install-login-destination.php"

  ## Setup userprotect
  #above# drush -y en userprotect
  for perm in "change own e-mail" "change own openid" "change own password" ; do
    drush role-remove-perm "authenticated user" "$perm"
  done

  install_civihr

  drush en front_page -y
  drush en civicrmtheme -y
  drush en civihr_employee_portal_features -y

  setup_themes
  create_default_users
  disabled_unused_blocks
  set_permissions
  create_personal_location_type
  delete_name_and_address_profile

  ## Create My Details and My Emergency Contact forms
  drush refresh-node-export-files

  ## Clear the cache
  drush cc all
popd >> /dev/null
