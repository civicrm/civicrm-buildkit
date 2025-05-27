#!/usr/bin/env bash

## install.sh -- Create config files and databases; fill the databases
CMS_ROOT="$WEB_ROOT"
CMS_VERSION="master"
###############################################################################
## Create virtual-host and databases

amp_install

###############################################################################
## Setup CiviCRM (config files, database tables)

CIVI_DOMAIN_NAME="Demonstrators Anonymous"
CIVI_DOMAIN_EMAIL="info@example.org"
CIVI_CORE="${WEB_ROOT}/core"
CIVI_UF="Standalone"
CIVI_SETTINGS="${WEB_ROOT}/private/civicrm.settings.php"
CIVI_TEMPLATEC="${WEB_ROOT}/private/cache"
GENCODE_CONFIG_TEMPLATE="${WEB_ROOT}/civicrm.standalone.php"
RPOW_SETTINGS_PATH="${WEB_ROOT}/private/civicrm.settings.d/pre.d/100-civirpow.php"
RPOW_RO_USER="civiwmfro"

## Clear out any cached container files to avoid it attempting to load
## the cached monolog service before the extension is installed.
rm -f ${CIVI_TEMPLATEC}/*.php

## Set site key if requested in Docker environment
[ ! -z "$FR_DOCKER_CIVI_SITE_KEY" ] && CIVI_SITE_KEY=${FR_DOCKER_CIVI_SITE_KEY}

pushd "$CIVI_CORE"
  # If you've switched branches and triggered `reinstall`, then you need to refresh composer deps/autoloader before installing
  # This probably adds ~1 second on new builds, but it can save umpteen minutes of confusion during triage/debugging.
  composer install
  echo "Running scaffold"
  ./tools/standalone/bin/scaffold "$CMS_ROOT"
  ## This may technically be a bit redundant with 'composer install' for new builds.
  ## But for long-lived sites that have rebuilds, it's handy.
popd

civicrm_install_cv

"${WEB_ROOT}/ext/rpow/bin/harvey-dent" --root "${WEB_ROOT}" --settings-path "${RPOW_SETTINGS_PATH}" --user-name "${RPOW_RO_USER}"
echo "DROP DATABASE IF EXISTS fredge"| amp sql -N civi -a
echo "CREATE DATABASE IF NOT EXISTS fredge"| amp sql -N civi -a
echo "CREATE DATABASE IF NOT EXISTS smashpig"| amp sql -N civi -a
eval mysql $CIVI_DB_ARGS <<EOSQL
  GRANT ALL PRIVILEGES ON fredge.* TO $CMS_DB_USER@'%';
  GRANT SELECT ON fredge.* TO $CIVI_DB_USER@'%';
  GRANT SELECT ON fredge.* TO $RPOW_RO_USER@'%';
  GRANT ALL PRIVILEGES ON smashpig.* TO $CMS_DB_USER@'%';
  GRANT SELECT ON smashpig.* TO $CIVI_DB_USER@'%';
  GRANT SELECT ON smashpig.* TO $RPOW_RO_USER@'%';
EOSQL

###############################################################################
## Extra configuration

# Settings appropriate to a dev environment
cv setting:set environment=Development
cv setting:set debug_enabled=1
civicrm_enable_riverlea_theme

echo "enabling wmf-civicrm"
cv en --ignore-missing rpow wmf-civicrm

echo "Adding API key to admin user"
[ ! -z "$FR_DOCKER_CIVI_API_KEY" ] && cv api4 Contact.update \
	'{"where":[["display_name","=","Standalone Admin"]],"values":{"api_key":"'$FR_DOCKER_CIVI_API_KEY'"}}'

echo "adding general wmf dev-specific settings"
DEV_SETTINGS_FILE="${WEB_ROOT}/private/wmf_settings_developer.json"
if [ -e "$DEV_SETTINGS_FILE" ]; then
  cv api3 -v --in=json setting.create < "$DEV_SETTINGS_FILE"
fi

echo "adding general wmf settings"
WMF_SETTINGS_FILE="${WEB_ROOT}/private/wmf_settings.json"
if [ -e "$WMF_SETTINGS_FILE" ]; then
  cv api3 -v --in=json setting.create debug=1 < "$WMF_SETTINGS_FILE"
fi

echo "adding anonymous user"
cv api3 Contact.create first_name='Anonymous' last_name=Anonymous email=fakeemail@wikimedia.org contact_type=Individual

echo "adding wmf roles"
WMF_ROLES_FILE="${WEB_ROOT}/private/wmf_roles.sh"
if [ -e "$WMF_ROLES_FILE" ]; then
   bash $WMF_ROLES_FILE
fi

# Create directories and settings for audit file processing
mkdir -p ${WEB_ROOT}/private/wmf_audit/logs
for processor in adyen amazon braintree dlocal fundraiseup gravy; do
  mkdir -p ${WEB_ROOT}/private/wmf_audit/$processor/incoming
  mkdir -p ${WEB_ROOT}/private/wmf_audit/$processor/completed
  mkdir -p ${WEB_ROOT}/private/wmf_audit/$processor/logs
done;
mkdir -p ${WEB_ROOT}/private/prometheus/
cv setting:set metrics_reporting_prometheus_path="${CMS_ROOT}/private/prometheus/"
