#!/bin/bash

## install.sh -- Create config files and databases; fill the databases
[ -d "$WEB_ROOT/web" ] && CMS_ROOT="$WEB_ROOT/web"

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
## Setup CiviCRM (config files, database tables)

CIVI_DOMAIN_NAME="Demonstrators Anonymous"
CIVI_DOMAIN_EMAIL="\"Demonstrators Anonymous\" <info@example.org>"
CIVI_CORE="${CMS_ROOT}/vendor/civicrm/civicrm-core"
CIVI_UF="Drupal8"
GENCODE_CONFIG_TEMPLATE="${CMS_ROOT}/modules/contrib/civicrm/civicrm.config.php.drupal"

pushd "${CMS_ROOT}/sites/${DRUPAL_SITE_DIR}" >> /dev/null
  civicrm_install_cv
popd >> /dev/null

###############################################################################
## Extra configuration
pushd "${CMS_ROOT}/sites/${DRUPAL_SITE_DIR}" >> /dev/null

  ## make sure drush functions are loaded
  drush8 cc drush -y

  ## Setup CiviCRM -- But not in 'clean' config!
  #echo '{"enable_components":["CiviEvent","CiviContribute","CiviMember","CiviMail","CiviReport","CiviPledge","CiviCase","CiviCampaign"]}' \
  #  | drush8 cvapi setting.create --in=json
  #civicrm_apply_demo_defaults
  #cv ev 'return CRM_Utils_System::synchronizeUsers();'

  ## Setup demo user
  civicrm_apply_d8_perm_defaults
  drush8 -y user-create --password="$DEMO_PASS" --mail="$DEMO_EMAIL" "$DEMO_USER"
  drush8 -y user-add-role demoadmin "$DEMO_USER"

  ## Setup userprotect
  drush8 -y en userprotect
  drush8 -y rmp authenticated 'userprotect.account.edit,userprotect.mail.edit,userprotect.pass.edit'

popd >> /dev/null

