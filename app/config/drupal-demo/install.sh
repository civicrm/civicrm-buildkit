#!/bin/bash

## install.sh -- Create config files and databases; fill the databases

###############################################################################
## Create virtual-host and databases

amp_install

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
drush -y en civicrm toolbar garland login_destination
drush -y vset theme_default garland

drush -y scr "$SITE_CONFIG_DIR/node-welcome.php"
drush -y vset site_frontpage "welcome"
drush -y scr "$SITE_CONFIG_DIR/login-destination.php"

echo 'update block set region ="sidebar_first" where module="user" and delta="login" and theme="garland"' | drush sql-cli
echo 'update block set region ="sidebar_first" where module="system" and delta="navigation" and theme="garland"' | drush sql-cli

drush -y en civicrm_webtest
drush -y user-create --password="$DEMO_PASS" --mail="$DEMO_EMAIL" "$DEMO_USER"
drush -y user-add-role civicrm_webtest_user "$DEMO_USER"
