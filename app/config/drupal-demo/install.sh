#!/bin/bash

## install.sh -- Create config files and databases; fill the databases

###############################################################################
## Create virtual-host and databases

## "amp create" outputs variables, CMS_URL, CMS_DB_* and CIVI_DB_*
if [ -n "$CMS_URL" ]; then
  eval $(amp create -f --root="$WEB_ROOT" --name=cms --prefix=CMS_ --url="$CMS_URL")
else
  eval $(amp create -f --root="$WEB_ROOT" --name=cms --prefix=CMS_)
fi
eval $(amp create -f --root="$WEB_ROOT" --name=civi --prefix=CIVI_ --no-url)

###############################################################################
## Setup Drupal (config files, database tables)

drupal_singlesite_install

###############################################################################
## Setup CiviCRM (config files, database tables)

CIVI_CORE="${WEB_ROOT}/sites/all/modules/civicrm"
CIVI_SETTINGS="${WEB_ROOT}/sites/default/civicrm.settings.php"
CIVI_FILES="${WEB_ROOT}/sites/default/files/civicrm"
CIVI_TEMPLATEC="${CIVI_FILES}/templates_c"
CIVI_UF="Drupal"

civicrm_install

###############################################################################
## Extra configuration

drush -y updatedb
drush -y dis overlay shortcut color
drush -y en civicrm toolbar civicrmtheme
drush -y vset theme_default seven
drush -y vset civicrmtheme_theme_admin seven
drush -y vset site_frontpage "civicrm/dashboard"

drush -y en civicrm_webtest
drush -y user-create --password="$DEMO_PASS" --mail="$DEMO_EMAIL" "$DEMO_USER"
drush -y user-add-role civicrm_webtest_user "$DEMO_USER"
