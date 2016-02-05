#!/bin/bash

## install.sh -- Create config files and databases; fill the databases

###############################################################################
## Create virtual-host and databases

amp_install

###############################################################################
## Grant access for the Drupal database user to access the Civi Database too

mysql $CIVI_DB_ARGS <<EOSQL

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

  drush -y updatedb
  drush -y dis overlay shortcut color
  drush -y en civicrm toolbar locale seven login_destination userprotect

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

  ## Install CiviHR (no sample data as default)
  bash ${CIVI_CORE}/tools/extensions/civihr/bin/drush-install.sh
  
  ## Install CiviHR (with sample data - if required)
  # bash ${CIVI_CORE}/tools/extensions/civihr/bin/drush-install.sh --with-sample-data
  
  ## Disable / Uninstall old extensions (temporary should be removed when we don't need the old HRjob anymore)
  drush cvapi extension.disable keys=org.civicrm.hrjob

  drush en front_page -y
  drush en civicrmtheme -y
  drush en civihr_employee_portal_features -y

  ## Setup drupal theme
  drush -y en civihr_default_theme
  drush -y vset theme_default civihr_default_theme

  ## Setup Civicrm and admin theme
  drush -y vset admin_theme seven
  drush -y vset civicrmtheme_theme_admin seven
  drush -y vset civicrmtheme_theme_public seven

  ## Create default users
  drush -y user-create --password="civihr_staff" --mail="civihr_staff@compucorp.co.uk" "civihr_staff"
  drush -y user-add-role civihr_staff "civihr_staff"

  drush -y user-create --password="civihr_manager" --mail="civihr_manager@compucorp.co.uk" "civihr_manager"
  drush -y user-add-role civihr_manager "civihr_manager"

  drush -y user-create --password="civihr_admin" --mail="civihr_admin@compucorp.co.uk" "civihr_admin"
  drush -y user-add-role civihr_admin "civihr_admin"

  ## Final permissions assignment
  # In Drupal, CiviCRM's toolbar looks messy unless you also activate Drupal's "toolbar", so we grant "access toolbar".
  # We've activated more components than typical web-test baseline, so grant rights to those components.
  for perm in \
    'access toolbar' \
    'administer CiviCase' 'access all cases and activities' 'access my cases and activities' 'add cases' 'delete in CiviCase' \
    'access HRJobs' 'edit HRJobs'
  do
    drush -y role-add-perm civihr_admin "$perm"
  done

popd >> /dev/null