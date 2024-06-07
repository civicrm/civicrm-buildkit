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
CIVI_CORE="${WEB_ROOT}/core"
CIVI_UF="Standalone"
CIVI_SETTINGS="${CMS_ROOT}/private/civicrm.settings.php"
CIVI_TEMPLATEC="${CMS_ROOT}/private/compiler_cache"
GENCODE_CONFIG_TEMPLATE="${CMS_ROOT}/civicrm.standalone.php"

pushd "$CIVI_CORE"
  # If you've switched branches and triggered `reinstall`, then you need to refresh composer deps/autoloader before installing
  # This probably adds ~1 second on new builds, but it can save umpteen minutes of confusion during triage/debugging.
  composer install

  ./tools/standalone/bin/scaffold "$CMS_ROOT"
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
