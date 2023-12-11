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
CIVI_CORE="${WEB_ROOT}/web/core"
CIVI_UF="Standalone"
CIVI_SETTINGS="${WEB_ROOT}/data/civicrm.settings.php"
CIVI_TEMPLATEC="${WEB_ROOT}/data/templates_c"
GENCODE_CONFIG_TEMPLATE="${CMS_ROOT}/civicrm.config.php.standalone"

pushd "$CIVI_CORE"
  ./tools/standalone/bin/scaffold "$WEB_ROOT"
  ## This may technically be a bit redundant with 'composer install' for new builds.
  ## But for long-lived sites that have rebuilds, it's handy.
popd

civicrm_install_cv

###############################################################################
## Extra configuration

# Settings appropriate to a dev environment
cv setting:set environment=Development
cv setting:set debug_enabled=1

env DEMO_USER="$DEMO_USER" DEMO_PASS="$DEMO_PASS" DEMO_EMAIL="$DEMO_EMAIL" \
  cv scr "$SITE_CONFIG_DIR/demo-user.php"
  ## Might be nice as a dedicated command...
