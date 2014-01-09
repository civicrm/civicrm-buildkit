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

  ## Joomla requires removal of "installation" directory, which mucks up git,
  ## so we'll push them off to the side.
  [ -d installation ] && mv installation .installation.bak
  [ -d .git ]         && mv .git .git.bak
popd >> /dev/null

###############################################################################
## Setup CiviCRM (config files, database tables)

CIVI_DOMAIN_NAME="Demonstrators Anonymous"
CIVI_DOMAIN_EMAIL="\"Demonstrators Anonymous\" <info@example.org>"
CIVI_CORE="${WEB_ROOT}/sites/all/modules/civicrm"
CIVI_SETTINGS="${WEB_ROOT}/sites/default/civicrm.settings.php"
CIVI_FILES="${WEB_ROOT}/sites/default/files/civicrm"
CIVI_TEMPLATEC="${CIVI_FILES}/templates_c"
CIVI_UF="Joomla"

#civicrm_install

set +x
echo "================================================================================"
echo "================================================================================"
echo "== NOTE: The 'joomla-demo' scripts are still in development. The following    =="
echo "== features are not supported:                                                =="
echo "==   - Install CiviCRM                                                        =="
echo "==   - Create demo user                                                       =="
echo "==   - Set permissions of demo user                                           =="
echo "================================================================================"
echo "================================================================================"
set -x
