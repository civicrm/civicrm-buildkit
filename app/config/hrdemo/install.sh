#!/bin/bash

## install.sh -- Create config files and databases; fill the databases

###############################################################################
## Create virtual-host and databases

amp_install

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
CIVI_EXT_DIR="${WEB_ROOT}/sites/${DRUPAL_SITE_DIR}/ext"
CIVI_EXT_URL="${CMS_URL}/sites/${DRUPAL_SITE_DIR}/ext"
CIVI_UF="Drupal"

civicrm_install

###############################################################################
## Extra configuration
pushd "${WEB_ROOT}/sites/${DRUPAL_SITE_DIR}" >> /dev/null

  drush -y updatedb
  drush -y dis overlay shortcut color
  drush -y en civicrm toolbar locale seven login_destination userprotect

  ## Setup theme
  #above# drush -y en seven
  drush -y vset theme_default seven

  ## Setup welcome page
  drush -y scr "$SITE_CONFIG_DIR/install-welcome.php"
  drush -y vset site_frontpage "welcome"

  ## Setup login_destination
  #above# drush -y en login_destination
  drush -y scr "$SITE_CONFIG_DIR/install-login-destination.php"

  ## Setup userprotect
  #above# drush -y en userprotect
  for perm in "change own e-mail" "change own openid" "change own password" ; do
    drush role-remove-perm "authenticated user" "$perm"
  done

  ## Setup demo user
  drush -y en civicrm_webtest
  drush -y user-create --password="$DEMO_PASS" --mail="$DEMO_EMAIL" "$DEMO_USER"
  drush -y user-add-role civicrm_webtest_user "$DEMO_USER"

  ## Install CiviHR
  bash ${CIVI_CORE}/tools/extensions/civihr/bin/drush-install.sh --with-sample-data

  ## Final permissions assignment
  # In Drupal, CiviCRM's toolbar looks messy unless you also activate Drupal's "toolbar", so we grant "access toolbar".
  # We've activated more components than typical web-test baseline, so grant rights to those components.
  for perm in \
    'access toolbar' \
    'administer CiviCase' 'access all cases and activities' 'access my cases and activities' 'add cases' 'delete in CiviCase' \
    'access HRJobs' 'edit HRJobs'
  do
    drush -y role-add-perm civicrm_webtest_user "$perm"
  done

popd >> /dev/null