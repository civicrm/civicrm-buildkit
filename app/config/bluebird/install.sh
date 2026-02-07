#!/usr/bin/env bash

## install.sh -- Create config files and databases; fill the databases

CMS_ROOT="$WEB_ROOT/web"

###############################################################################
## Helper functions

## Update items in the `bluebird.cfg` file.
##
## usage: bluecfg <SECTION> <KEY> <VALUE>
## example: bluecfg globals site.key abcd1234
function bluecfg() {
  crudini --set "$WEB_ROOT/bluebird.cfg" "$@"
}

## Filter SQL data, replacing the DEFINER with our own DB user.
## (Quick-and-dirty; for proof-of-concept)
##
## example: cat foo.mysql | fix_definer | mysql
function fix_definer() {
  sed "s/DEFINER=\`[^\`]*\`@\`[^\`]*\`/DEFINER=\`$CIVI_DB_USER\`@\`localhost\`/g"
}

## usage: parse_url <URL> <COMPONENT>
## example: HTTP_PORT=$(parse_url "$CMS_URL" port)
function parse_url() {
  php -r 'echo parse_url($argv[1])[$argv[2]] . "\n";' "$@"
}

###############################################################################
## Create virtual-host and databases

amp_install
bluebird_http_port=$(parse_url "$CMS_URL" port)

###############################################################################
## Setup Bluebird

pushd "$WEB_ROOT" >> /dev/null
  ## Make some folder for local data
  mkdir -p local
  amp data drupal/data local/import

  ## Build the main INI file
  cp -f templates/bluebird.cfg bluebird.cfg

  bluecfg globals app.rootdir "$WEB_ROOT"
  bluecfg globals data.rootdir "$WEB_ROOT/drupal/data"
  bluecfg globals drupal.rootdir "$WEB_ROOT/drupal"
  bluecfg globals import.rootdir "$WEB_ROOT/local/import"
  bluecfg globals site.key "$CIVI_SITE_KEY"

  if [ -n "$bluebird_http_port" ]; then
    bluecfg globals http.port "$bluebird_http_port"
  fi

  if [ -n "$MAIL_SMTP_PORT" ]; then
    bluecfg globals smtp.host "${LOCALHOST:-127.0.0.1}"
    bluecfg globals smtp.port "$MAIL_SMTP_PORT"
    bluecfg globals smtp.auth 0
    bluecfg globals smtp.domain $(php -r '$u=parse_url($argv[1]); echo $u["host"];' "$CMS_URL")
    bluecfg "instance:$SITE_NAME" smtp.username ''
    bluecfg "instance:$SITE_NAME" smtp.api.key ''
  fi

  bluecfg "instance:$SITE_NAME" data.dirname "$SITE_NAME"
  bluecfg "instance:$SITE_NAME" datasets ''
  bluecfg "instance:$SITE_NAME" ldap.logingroups ''
  bluecfg "instance:$SITE_NAME" base.domain $(
    php -r '$u=parse_url($argv[1]); echo preg_replace(";^[^\\.]+\\.;", "", $u["host"]);' "$CMS_URL"
  )

  bluecfg "instance:$SITE_NAME" db.basename "$SITE_NAME"
  bluecfg "instance:$SITE_NAME" db.host "$CIVI_DB_HOST"
  bluecfg "instance:$SITE_NAME" db.port "$CIVI_DB_PORT"
  bluecfg "instance:$SITE_NAME" db.user "$CIVI_DB_USER"
  bluecfg "instance:$SITE_NAME" db.pass "$CIVI_DB_PASS"

  ## FIXME: Some sample values cause parse errors in PHP's parse_ini_file(). Coerce them to safe content.
  bluecfg globals email.extras.whitelist_html 'FIXME email.extras.whitelist_html'
  bluecfg globals email.extras.whitelist_text 'FIXME email.extras.whitelist_text'

  ## Create databases. Grant access to them.
  SITE_NAME="$SITE_NAME" CIVI_DB_USER="$CIVI_DB_USER" amp sql -ae <<EOSQL
    DROP DATABASE IF EXISTS senate_c_!ENV[SITE_NAME];
    DROP DATABASE IF EXISTS senate_d_!ENV[SITE_NAME];
    DROP DATABASE IF EXISTS senate_l_!ENV[SITE_NAME];

    CREATE DATABASE senate_c_!ENV[SITE_NAME];
    CREATE DATABASE senate_d_!ENV[SITE_NAME];
    CREATE DATABASE senate_l_!ENV[SITE_NAME];

    GRANT ALL PRIVILEGES ON senate_c_!ENV[SITE_NAME].* to @ENV[CIVI_DB_USER]@'localhost';
    GRANT ALL PRIVILEGES ON senate_d_!ENV[SITE_NAME].* to @ENV[CIVI_DB_USER]@'localhost';
    GRANT ALL PRIVILEGES ON senate_l_!ENV[SITE_NAME].* to @ENV[CIVI_DB_USER]@'localhost';
    GRANT SUPER on *.* to  @ENV[CIVI_DB_USER]@'localhost';
    FLUSH PRIVILEGES;
EOSQL

  ## In a few moments, we'll have weakly-escaped reference to ADMIN_USER.
  cvutil_assert_regex '^[0-9a-z][0-9a-z_]*$' "$ADMIN_USER" "ADMIN_USER must be a basic word"

  ## Populate databases
  (
    echo "CONNECT senate_c_$SITE_NAME;"
    #cat templates/sql/cividb_template.sql | fix_definer
    cat templates/sql/senate_test_c_template.sql | fix_definer
    cat civicrm/custom/ext/gov.nysenate.dedupe/sql/shadow_func.sql

    echo "CONNECT senate_d_$SITE_NAME;"
    #cat templates/sql/drupdb_template.sql | fix_definer
    cat templates/sql/senate_test_d_template.sql | fix_definer

    ## FIXME: Various work-arounds
    # echo 'update `system` set status = 0 where name like "%rules%";'
    echo 'update `users` set name = "'$ADMIN_USER'" where uid=1;'
    echo 'update `system` set status = 0 where name like "%ldap%";'
    echo "truncate cache; truncate cache_apachesolr; truncate cache_block; truncate cache_bootstrap; truncate cache_field; truncate cache_filter; truncate cache_form;"
    echo "truncate cache_menu; truncate cache_page; truncate cache_path; truncate cache_rules; truncate cache_update;"

    echo "CONNECT senate_l_$SITE_NAME;"
    #cat templates/sql/logdb_template.sql | fix_definer
    cat templates/sql/senate_test_l_template.sql | fix_definer

    ## Override some settings via SQL.
    ## FIXME: This could probably be done declaratively in civicrm.settings.php...
    echo "CONNECT senate_c_$SITE_NAME;"
    echo "set @root = '$WEB_ROOT';"
    cat scripts/setCiviDirs.sql
  ) | amp sql -a

  ( cd scripts && php manageCiviConfig.php "$SITE_NAME" update def )

  ./scripts/drush.sh "$SITE_NAME" -y upwd "$ADMIN_USER" --password="$ADMIN_PASS"
  ## FIXME: ADMIN_EMAIL
  ./scripts/drush.sh "$SITE_NAME" -y user-create --password="$DEMO_PASS" --mail="$DEMO_EMAIL" "$DEMO_USER"

  chmod u+w drupal/sites/default/settings.php drupal/sites/default/civicrm.settings.php
  cvutil_inject_settings "drupal/sites/default/civicrm.settings.php" "civicrm.settings.d"
  cvutil_inject_settings "drupal/sites/default/settings.php" "drupal.settings.d"

popd >> /dev/null
