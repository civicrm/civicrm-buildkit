#!/bin/bash

## Bash helper functions

## Coding conventions:
## - Function names are "{prefix}_{name}"; prefixes are "util", "civicrm", "wp", etc
## - Options are set as (global) environment variables
## - Functions declare dependencies on (global) environment variables (util_assertvars).
##   If a variable missing, the application dies.

###############################################################################
## Assert that shell variables are defined. If not defined, exit with an error.
## usage: assertvars <context> <var1> <var2> <var3> ...
function cvutil_assertvars() {
  _cvutil_assertvars_back="$-"

  set +x
  context="$1"
  shift
  while [ "$1" ]; do
    var="$1"
    eval "val=\$$var"
    if [ -z "$val" ]; then
      echo "missing variable: $var [in $context]"
      exit 98
    fi
    shift
  done

  set -${_cvutil_assertvars_back}
}

###############################################################################
## Save a list of environment variables to a file
## usage: cvutil_save() <filename> <var1> <var2> ...
function cvutil_save() {
  file="$1"
  shift

  echo "#!/bin/bash" > $file
  for var in "$@" ; do
    eval "val=\$$var"
    echo "$var=\"$val\"" >> $file
  done
}

###############################################################################
## Summarize the content of key environment variables
## usage: cvutil_summary <message> <var1> <var2> ...
function cvutil_summary() {
  echo "========================================"
  echo $1
  shift

  cvutil_assertvars "$@"
  for var in "$@" ; do
    eval "val=\$$var"
    echo " - $var: $val"
  done
}


###############################################################################
## usage: cvutil_makepasswd <strlen>
function cvutil_makepasswd() {
  php $PRJDIR/bin/mkpasswd.php $1
}

###############################################################################
## Reset a MySQL database ($DB_NAME) and grant access to $DB_USER/$DB_PASS
function mysql_dropcreate() {
  cvutil_assertvars mysql_dropcreate MYSQLCLI DB_NAME DB_USER DB_PASS

  echo "DROP DATABASE IF EXISTS $DB_NAME" | $MYSQLCLI
  echo "CREATE DATABASE $DB_NAME" | $MYSQLCLI
  echo "GRANT ALL ON ${DB_NAME}.* TO '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}'" | $MYSQLCLI
  echo "GRANT SUPER ON *.* TO '${DB_USER}'@'localhost'" | $MYSQLCLI
}

###############################################################################
## Generate config files and setup database
function civicrm_install() {
  cvutil_assertvars civicrm_install CIVI_ROOT CIVI_FILES CIVI_TEMPLATEC

  if [ ! -d "$CIVI_ROOT/bin" -o ! -d "$CIVI_ROOT/CRM" ]; then
    echo "Failed to locate valid civi root: $CIVI_ROOT"
    exit 1
  fi

  ## Create CiviCRM data dirs
  for DIR in "$CIVI_FILES" "$CIVI_TEMPLATEC" ; do
    if [ ! -d "$DIR" ]; then
      mkdir -p "$DIR"
    fi
  done

  ## Create CiviCRM config files
  civicrm_make_settings_php
  civicrm_make_setup_conf
  civicrm_make_test_settings_php

  pushd "$CIVI_ROOT" >> /dev/null
    ./bin/setup.sh
  popd >> /dev/null
}

###############################################################################
## Generate a "civicrm.settings.php" file
function civicrm_make_settings_php() {
  cvutil_assertvars civicrm_make_settings_php CIVI_SETTINGS CIVI_ROOT CIVI_UF CIVI_TEMPLATEC SITE_URL DB_HOST DB_NAME DB_PASS DB_USER DB_HOST DB_NAME DB_PASS DB_USER SITE_KEY

  cat "$CIVI_ROOT/templates/CRM/common/civicrm.settings.php.template" \
    | sed "s;%%baseURL%%;${SITE_URL};" \
    | sed "s;%%cms%%;${CIVI_UF};" \
    | sed "s;%%CMSdbHost%%;${DB_HOST};" \
    | sed "s;%%CMSdbName%%;${DB_NAME};" \
    | sed "s;%%CMSdbPass%%;${DB_PASS};" \
    | sed "s;%%CMSdbUser%%;${DB_USER};" \
    | sed "s;%%crmRoot%%;${CIVI_ROOT}/;" \
    | sed "s;%%dbHost%%;${DB_HOST};" \
    | sed "s;%%dbName%%;${DB_NAME};" \
    | sed "s;%%dbPass%%;${DB_PASS};" \
    | sed "s;%%dbUser%%;${DB_USER};" \
    | sed "s;%%siteKey%%;${SITE_KEY};" \
    | sed "s;%%templateCompileDir%%;${CIVI_TEMPLATEC};" \
    > "$CIVI_SETTINGS"
  echo  >> "$CIVI_SETTINGS"
  echo "define('CIVICRM_MAIL_LOG', '/dev/null');" >> "$CIVI_SETTINGS"
}

###############################################################################
## Generate a "setup.conf" file
function civicrm_make_setup_conf() {
  cvutil_assertvars civicrm_make_setup_conf CIVI_ROOT CIVI_UF DB_NAME DB_USER DB_PASS

  cat > "$CIVI_ROOT/bin/setup.conf" << EOF
    SVNROOT="$CIVI_ROOT"
    CIVISOURCEDIR="$CIVI_ROOT"
    SCHEMA=schema/Schema.xml
    DBNAME="$DB_NAME"
    DBUSER="$DB_USER"
    DBPASS="$DB_PASS"
    DBARGS=""
    PHP5PATH=
    DBLOAD="$DBLOAD"
    # DBADD=
    GENCODE_CMS="$CIVI_UF"
EOF
}

###############################################################################
## Generate civicrm.settings.php and CiviSeleniumSettings.php for testing
function civicrm_make_test_settings_php() {
  cvutil_assertvars civicrm_make_test_settings_php CIVI_ROOT DB_NAME DB_USER DB_PASS DB_HOST WEB_ROOT SITE_URL ADMIN_USER ADMIN_PASS DEMO_USER DEMO_PASS SITE_KEY

  ## TODO: REVIEW
  cat > "$CIVI_ROOT/tests/phpunit/CiviTest/civicrm.settings.local.php" << EOF
<?php
  define('CIVICRM_DSN', "mysql://${DB_USER}:${DB_PASS}@${DB_HOST}/${DB_NAME}");
  define('CIVICRM_TEMPLATE_COMPILEDIR', '${CIVI_TEMPLATEC}');
  define('DONT_DOCUMENT_TEST_CONFIG', TRUE);
EOF

  ## TODO: REVIEW
  cat > "$CIVI_ROOT/tests/phpunit/CiviTest/CiviSeleniumSettings.php" << EOF
<?php
class CiviSeleniumSettings {
	var \$publicSandbox  = false;
	var \$browser = '*firefox';
	var \$sandboxURL = '${SITE_URL}';
	var \$sandboxPATH = '';
	var \$username = '${DEMO_USER}';
	var \$password = '${DEMO_PASS}';
	var \$adminUsername = '${ADMIN_USER}';
	var \$adminPassword = '${ADMIN_PASS}';
	var \$adminApiKey = 'apikey${ADMIN_PASS}';
	var \$siteKey = '${SITE_KEY}';
        var \$UFemail = 'noreply@civicrm.org';
	function __construct() {
		\$this->fullSandboxPath = \$this->sandboxURL . \$this->sandboxPATH;
	}
}
EOF
}

###############################################################################
## Generate config files and setup database
function wp_install() {
  cvutil_assertvars wp_install WEB_ROOT DB_NAME DB_USER DB_PASS DB_HOST SITE_URL ADMIN_USER ADMIN_PASS ADMIN_EMAIL SITE_TITLE FACL_USERS

  pushd "$WEB_ROOT" >> /dev/null
    [ -f "wp-config.php" ] && rm -f "wp-config.php"
    wp core config \
      --dbname="$DB_NAME" \
      --dbuser="$DB_USER" \
      --dbpass="$DB_PASS" \
      --dbhost="$DB_HOST" \
      --skip-salts \
      --extra-php <<PHP
        define('AUTH_KEY',         '$(cvutil_makepasswd 32)');
        define('SECURE_AUTH_KEY',  '$(cvutil_makepasswd 32)');
        define('LOGGED_IN_KEY',    '$(cvutil_makepasswd 32)');
        define('NONCE_KEY',        '$(cvutil_makepasswd 32)');
        define('AUTH_SALT',        '$(cvutil_makepasswd 32)');
        define('SECURE_AUTH_SALT', '$(cvutil_makepasswd 32)');
        define('LOGGED_IN_SALT',   '$(cvutil_makepasswd 32)');
        define('NONCE_SALT',       '$(cvutil_makepasswd 32)');
PHP

    wp core install \
      --url="$SITE_URL" \
      --admin_user="$ADMIN_USER" \
      --admin_password="$ADMIN_PASS" \
      --admin_email="$ADMIN_EMAIL" \
      --title="$SITE_TITLE"

    ## Create WP data dirs
    for SUBDIR in modules files ; do
      if [ ! -d "wp-content/plugins/${SUBDIR}" ]; then
        mkdir "wp-content/plugins/${SUBDIR}"
      fi
    done

    ## Allow shell and WWW users to both manipulate "files" directory
    if which setfacl; then
      for FACL_USER in $FACL_USERS ; do
        find "$WEB_ROOT/wp-content/plugins/files" -type d | xargs setfacl -m u:${FACL_USER}:rwx -m d:u:${FACL_USER}:rwx
      done
    fi
  popd >> /dev/null
}

###############################################################################
## Generate config files and setup database
function drupal_install() {
  cvutil_assertvars drupal_install WEB_ROOT SITE_TITLE SITE_DIR DB_USER DB_PASS DB_HOST DB_NAME ADMIN_USER ADMIN_PASS

  pushd "$WEB_ROOT" >> /dev/null
    [ -f "sites/$SITE_DIR/settings.php" ] && rm -f "sites/$SITE_DIR/settings.php"

    drush site-install -y \
      --db-url="mysql://${DB_USER}:${DB_PASS}@${DB_HOST}/${DB_NAME}" \
      --account-name="$ADMIN_USER" \
      --account-pass="$ADMIN_PASS" \
      --account-mail="$ADMIN_EMAIL" \
      --site-name="$SITE_TITLE" \
      --sites-subdir="$SITE_DIR"
    chmod u+w "sites/$SITE_DIR"

    ## Allow shell and WWW users to both manipulate "files" directory
    if which setfacl; then
      for FACL_USER in $FACL_USERS ; do
        find "$DRUPAL_ROOT/sites/${SITE_DIR}/files" -type d | xargs setfacl -m u:${FACL_USER}:rwx -m d:u:${FACL_USER}:rwx
      done
    fi

    ## Create Drupal-CiviCRM dirs and config
    for SUBDIR in modules files ; do
      if [ ! -d "sites/${SITE_DIR}/${SUBDIR}" ]; then
        mkdir "sites/${SITE_DIR}/${SUBDIR}"
      fi
    done
  popd >> /dev/null
}
