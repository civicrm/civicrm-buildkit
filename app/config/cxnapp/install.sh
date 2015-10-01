#!/bin/bash

## install.sh -- Create config files and databases; fill the databases

CMS_ROOT="$WEB_ROOT/web"
CXNAPP_BASE_DN="${CXNAPP_BASE_DN:-O=Local Demo}"

###############################################################################
## Create virtual-host and databases

amp_install

###############################################################################
## Setup config files

amp datadir "$WEB_ROOT/app/cache" "$WEB_ROOT/app/logs"

cat > "$WEB_ROOT/app/config/parameters.yml" << EOSETTING
# This file is auto-generated during the composer install
parameters:
    database_host: '$CMS_DB_HOST'
    database_port: $CMS_DB_PORT
    database_name: $CMS_DB_NAME
    database_user: $CMS_DB_USER
    database_password: '$CMS_DB_PASS'
    mailer_transport: smtp
    mailer_host: 127.0.0.1
    mailer_user: null
    mailer_password: null
    secret: '$(cvutil_makepasswd 32)'
EOSETTING

pushd "$WEB_ROOT" >> /dev/null
  composer install
  ./app/console doctrine:schema:create
  ./app/console cxnapp:init org.civicrm.cron "$CXNAPP_BASE_DN"
  ./app/console dirsvc:init "$CXNAPP_BASE_DN"
popd >> /dev/null
