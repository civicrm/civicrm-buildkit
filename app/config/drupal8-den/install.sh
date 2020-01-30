#!/bin/bash

## install.sh -- Create config files and databases; fill the databases
CMS_ROOT="$WEB_ROOT/web"

###############################################################################
## Create virtual-host and databases

amp_install

###############################################################################
## Setup Drupal (config files, database tables)

drupal8_install
DRUPAL_SITE_DIR=$(_drupal_multisite_dir "$CMS_URL" "$SITE_ID")
pushd "${CMS_ROOT}/sites/${DRUPAL_SITE_DIR}" >> /dev/null
  drush8 -y updatedb
  drush8 -y en libraries
popd >> /dev/null

###############################################################################
## Extra configuration
pushd "${CMS_ROOT}/sites/${DRUPAL_SITE_DIR}" >> /dev/null

  ## make sure drush functions are loaded
  drush8 cc drush -y

  ## Setup CiviCRM -- But not in 'clean' config!
  drush8 -y en -l "$CMS_URL" civicrm
  #x civicrm_apply_demo_defaults
  #x cv ev 'return CRM_Utils_System::synchronizeUsers();'

  ## Setup demo user
  #x civicrm_apply_d8_perm_defaults
  #x drush8 -y user-create --password="$DEMO_PASS" --mail="$DEMO_EMAIL" "$DEMO_USER"
  #x drush8 -y user-add-role demoadmin "$DEMO_USER"

  ## Setup userprotect
  drush8 -y en userprotect
  drush8 -y rmp authenticated userprotect.account.edit
  drush8 -y rmp authenticated userprotect.mail.edit
  drush8 -y rmp authenticated userprotect.pass.edit

popd >> /dev/null
