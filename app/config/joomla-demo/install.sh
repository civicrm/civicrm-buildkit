#!/bin/bash

## install.sh -- Create config files and databases; fill the databases

###############################################################################
## Create virtual-host and databases

amp_install

###############################################################################
## Setup Joomla (config files, database tables)

pushd "$WEB_ROOT" >> /dev/null
  CMS_DB_HOSTPORT=$(cvutil_build_hostport "$CMS_DB_HOST" "$CMS_DB_PORT")
  php cli/install.php \
    --db-user="$CMS_DB_USER" \
    --db-name="$CMS_DB_NAME" \
    --db-host="$CMS_DB_HOSTPORT" \
    --db-pass="$CMS_DB_PASS" \
    --admin-user="$ADMIN_USER" \
    --admin-pass="$ADMIN_PASS" \
    --admin-email="$ADMIN_EMAIL" \
    --offline

  mv installation .installation.bak
popd >> /dev/null

###############################################################################
## Setup CiviCRM (config files, database tables)

CIVI_CORE="${WEB_ROOT}/sites/all/modules/civicrm"
CIVI_SETTINGS="${WEB_ROOT}/sites/default/civicrm.settings.php"
CIVI_FILES="${WEB_ROOT}/sites/default/files/civicrm"
CIVI_TEMPLATEC="${CIVI_FILES}/templates_c"
CIVI_UF="Drupal"

#civicrm_install
