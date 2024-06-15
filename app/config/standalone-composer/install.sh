#!/usr/bin/env bash

## install.sh -- Create config files and databases; fill the databases
[ -d "$WEB_ROOT/web" ] && CMS_ROOT="$WEB_ROOT/web"

###############################################################################
## Create virtual-host and databases

amp_install

###############################################################################
## Setup CiviCRM (config files, database tables)

CIVI_DOMAIN_NAME="Demonstrators Anonymous"
CIVI_DOMAIN_EMAIL="\"Demonstrators Anonymous\" <info@example.org>"
CIVI_CORE="${CMS_ROOT}/vendor/civicrm/civicrm-core"
CIVI_UF="Standalone"
CIVI_SETTINGS="${CMS_ROOT}/private/civicrm.settings.php"
CIVI_TEMPLATEC="${CMS_ROOT}/private/cache"
GENCODE_CONFIG_TEMPLATE="${CMS_ROOT}/civicrm.standalone.php"

civicrm_install_cv

pushd "$CMS_ROOT"
  composer civicrm:publish
popd

###############################################################################
## Extra configuration

env DEMO_USER="$DEMO_USER" DEMO_PASS="$DEMO_PASS" DEMO_EMAIL="$DEMO_EMAIL" \
  cv scr "$SITE_CONFIG_DIR/demo-user.php"
  ## Might be nice as a dedicated command...

