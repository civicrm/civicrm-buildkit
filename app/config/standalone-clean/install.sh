#!/bin/bash

## install.sh -- Create config files and databases; fill the databases
[ -d "$WEB_ROOT/web" ] && CMS_ROOT="$WEB_ROOT/web"

###############################################################################
## Create virtual-host and databases

amp_install

###############################################################################
## Setup CiviCRM (config files, database tables)

CIVI_DOMAIN_NAME="Demonstrators Anonymous"
CIVI_DOMAIN_EMAIL="\"Demonstrators Anonymous\" <info@example.org>"
CIVI_CORE="${WEB_ROOT}/vendor/civicrm/civicrm-core"
CIVI_UF="Standalone"
CIVI_SETTINGS="${WEB_ROOT}/data/civicrm.settings.php"
CIVI_TEMPLATEC="${WEB_ROOT}/data/templates_c"
GENCODE_CONFIG_TEMPLATE="${CMS_ROOT}/civicrm.config.php.standalone"

civicrm_install_cv

composer civicrm:publish

###############################################################################
## Extra configuration
# @todo Setup demo user
