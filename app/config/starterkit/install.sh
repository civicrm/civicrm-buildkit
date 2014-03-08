#!/bin/bash

## install.sh -- Create config files and databases; fill the databases

###############################################################################
## Create virtual-host and databases

amp_install

###############################################################################
## Setup CiviCRM (config files, database tables)

DRUPAL_SITE_DIR=$(_drupal_multisite_dir "$CMS_URL" "$SITE_ID")
CIVI_DOMAIN_NAME="Demonstrators Anonymous"
CIVI_DOMAIN_EMAIL="\"Demonstrators Anonymous\" <info@example.org>"
CIVI_CORE="${WEB_ROOT}/profiles/civicrm_starterkit/modules/civicrm"
CIVI_SETTINGS="${WEB_ROOT}/sites/${DRUPAL_SITE_DIR}/civicrm.settings.php"
CIVI_FILES="${WEB_ROOT}/sites/${DRUPAL_SITE_DIR}/files/civicrm"
CIVI_TEMPLATEC="${CIVI_FILES}/templates_c"
CIVI_UF="Drupal"

civicrm_install

###############################################################################
## Setup Drupal (config files, database tables)

drupal_install civicrm_starterkit

###############################################################################
## Extra configuration
pushd "${WEB_ROOT}/sites/${DRUPAL_SITE_DIR}" >> /dev/null

  ## Setup demo user
  #drush -y en civicrm_webtest
  drush -y user-create --password="$DEMO_PASS" --mail="$DEMO_EMAIL" "$DEMO_USER"
  #drush -y user-add-role civicrm_webtest_user "$DEMO_USER"

popd >> /dev/null