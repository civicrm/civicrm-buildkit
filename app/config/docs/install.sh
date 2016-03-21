#!/bin/bash

## install.sh -- Create config files and databases; fill the databases

CMS_ROOT="$WEB_ROOT/web"

###############################################################################
## Create virtual-host and databases

amp_install

###############################################################################
## Setup config files

# Std Symfony dirs. Some dirs already commited in git, so we set perms on each.
amp datadir "$WEB_ROOT/var" "$WEB_ROOT/var/cache" "$WEB_ROOT/var/logs" "$WEB_ROOT/var/sessions"

# This is default location where civicrm-docs publishes its builds.
amp datadir "$WEB_ROOT/web/static"

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
  #./app/console doctrine:schema:create
popd >> /dev/null
