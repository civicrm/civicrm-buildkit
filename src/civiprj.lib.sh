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
## Ensure that the parent directory exists
## usage: cvutil_makeparent <file>
function cvutil_makeparent() {
  parent=$(dirname "$1")
  if [ ! -d "$parent" ]; then
    mkdir -p "$parent"
  fi
}

###############################################################################
## Generate config files and setup database
function civicrm_install() {
  cvutil_assertvars civicrm_install CIVI_CORE CIVI_FILES CIVI_TEMPLATEC

  if [ ! -d "$CIVI_CORE/bin" -o ! -d "$CIVI_CORE/CRM" ]; then
    echo "Failed to locate valid civi root: $CIVI_CORE"
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

  pushd "$CIVI_CORE" >> /dev/null
    ./bin/setup.sh
  popd >> /dev/null
}

###############################################################################
## Generate a "civicrm.settings.php" file
function civicrm_make_settings_php() {
  cvutil_assertvars civicrm_make_settings_php CIVI_SETTINGS CIVI_CORE CIVI_UF CIVI_TEMPLATEC CMS_URL CIVI_SITE_KEY
  cvutil_assertvars civicrm_make_settings_php CMS_DB_HOST CMS_DB_NAME CMS_DB_PASS CMS_DB_USER
  cvutil_assertvars civicrm_make_settings_php CIVI_DB_HOST CIVI_DB_NAME CIVI_DB_PASS CIVI_DB_USER

  cat "$CIVI_CORE/templates/CRM/common/civicrm.settings.php.template" \
    | sed "s;%%baseURL%%;${CMS_URL};" \
    | sed "s;%%cms%%;${CIVI_UF};" \
    | sed "s;%%CMSdbHost%%;${CMS_DB_HOST};" \
    | sed "s;%%CMSdbName%%;${CMS_DB_NAME};" \
    | sed "s;%%CMSdbPass%%;${CMS_DB_PASS};" \
    | sed "s;%%CMSdbUser%%;${CMS_DB_USER};" \
    | sed "s;%%crmRoot%%;${CIVI_CORE}/;" \
    | sed "s;%%dbHost%%;${CIVI_DB_HOST};" \
    | sed "s;%%dbName%%;${CIVI_DB_NAME};" \
    | sed "s;%%dbPass%%;${CIVI_DB_PASS};" \
    | sed "s;%%dbUser%%;${CIVI_DB_USER};" \
    | sed "s;%%siteKey%%;${CIVI_SITE_KEY};" \
    | sed "s;%%templateCompileDir%%;${CIVI_TEMPLATEC};" \
    > "$CIVI_SETTINGS"
  echo  >> "$CIVI_SETTINGS"
  echo "define('CIVICRM_MAIL_LOG', '/dev/null');" >> "$CIVI_SETTINGS"
}

###############################################################################
## Generate a "setup.conf" file
function civicrm_make_setup_conf() {
  cvutil_assertvars civicrm_make_setup_conf CIVI_CORE CIVI_UF CIVI_DB_NAME CIVI_DB_USER CIVI_DB_PASS

  cat > "$CIVI_CORE/bin/setup.conf" << EOF
    SVNROOT="$CIVI_CORE"
    CIVISOURCEDIR="$CIVI_CORE"
    SCHEMA=schema/Schema.xml
    DBNAME="$CIVI_DB_NAME"
    DBUSER="$CIVI_DB_USER"
    DBPASS="$CIVI_DB_PASS"
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
  cvutil_assertvars civicrm_make_test_settings_php CIVI_CORE CIVI_DB_NAME CIVI_DB_USER CIVI_DB_PASS CIVI_DB_HOST WEB_ROOT CMS_URL ADMIN_USER ADMIN_PASS DEMO_USER DEMO_PASS CIVI_SITE_KEY

  ## TODO: REVIEW
  cat > "$CIVI_CORE/tests/phpunit/CiviTest/civicrm.settings.local.php" << EOF
<?php
  define('CIVICRM_DSN', "mysql://${CIVI_DB_USER}:${CIVI_DB_PASS}@${CIVI_DB_HOST}/${CIVI_DB_NAME}");
  define('CIVICRM_TEMPLATE_COMPILEDIR', '${CIVI_TEMPLATEC}');
  define('DONT_DOCUMENT_TEST_CONFIG', TRUE);
EOF

  ## TODO: REVIEW
  cat > "$CIVI_CORE/tests/phpunit/CiviTest/CiviSeleniumSettings.php" << EOF
<?php
class CiviSeleniumSettings {
	var \$publicSandbox  = false;
	var \$browser = '*firefox';
	var \$sandboxURL = '${CMS_URL}';
	var \$sandboxPATH = '';
	var \$username = '${DEMO_USER}';
	var \$password = '${DEMO_PASS}';
	var \$adminUsername = '${ADMIN_USER}';
	var \$adminPassword = '${ADMIN_PASS}';
	var \$adminApiKey = 'apikey${ADMIN_PASS}';
	var \$siteKey = '${CIVI_SITE_KEY}';
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
  cvutil_assertvars wp_install WEB_ROOT CMS_DB_NAME CMS_DB_USER CMS_DB_PASS CMS_DB_HOST CMS_URL ADMIN_USER ADMIN_PASS ADMIN_EMAIL CMS_TITLE FACL_USERS

  pushd "$WEB_ROOT" >> /dev/null
    [ -f "wp-config.php" ] && rm -f "wp-config.php"
    wp core config \
      --dbname="$CMS_DB_NAME" \
      --dbuser="$CMS_DB_USER" \
      --dbpass="$CMS_DB_PASS" \
      --dbhost="$CMS_DB_HOST" \
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
      --url="$CMS_URL" \
      --admin_user="$ADMIN_USER" \
      --admin_password="$ADMIN_PASS" \
      --admin_email="$ADMIN_EMAIL" \
      --title="$CMS_TITLE"

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
## Destroy config files and database tables
function wp_uninstall() {
  cvutil_assertvars wp_uninstall WEB_ROOT
  pushd "$WEB_ROOT" >> /dev/null
    [ -f "wp-config.php" ] && rm -f "wp-config.php"
    [ -f "wp-content/plugins/files" ] && rm -rf "wp-content/plugins/files"
  popd >> /dev/null
}

###############################################################################
## Generate config files and setup database
function drupal_multisite_install() {
  cvutil_assertvars drupal_multisite_install WEB_ROOT CMS_TITLE CMS_DB_USER CMS_DB_PASS CMS_DB_HOST CMS_DB_NAME ADMIN_USER ADMIN_PASS FACL_USERS CMS_URL
  DRUPAL_SITE_DIR=$(_drupal_multisite_dir "$CMS_URL")

  pushd "$WEB_ROOT" >> /dev/null
    [ -f "sites/$DRUPAL_SITE_DIR/settings.php" ] && rm -f "sites/$DRUPAL_SITE_DIR/settings.php"

    drush site-install -y \
      --db-url="mysql://${CMS_DB_USER}:${CMS_DB_PASS}@${CMS_DB_HOST}/${CMS_DB_NAME}" \
      --account-name="$ADMIN_USER" \
      --account-pass="$ADMIN_PASS" \
      --account-mail="$ADMIN_EMAIL" \
      --site-name="$CMS_TITLE" \
      --sites-subdir="$DRUPAL_SITE_DIR"
    chmod u+w "sites/$DRUPAL_SITE_DIR"

    ## Allow shell and WWW users to both manipulate "files" directory
    if which setfacl; then
      for FACL_USER in $FACL_USERS ; do
        find "$DRUPAL_ROOT/sites/${DRUPAL_SITE_DIR}/files" -type d | xargs setfacl -m u:${FACL_USER}:rwx -m d:u:${FACL_USER}:rwx
      done
    fi

    ## Create Drupal-CiviCRM dirs and config
    for SUBDIR in modules files ; do
      if [ ! -d "sites/${DRUPAL_SITE_DIR}/${SUBDIR}" ]; then
        mkdir "sites/${DRUPAL_SITE_DIR}/${SUBDIR}"
      fi
    done
  popd >> /dev/null
}

###############################################################################
## Drupal Multi-Site -- Destroy config files and database tables
function drupal_multisite_uninstall() {
  cvutil_assertvars drupal_multisite_uninstall WEB_ROOT CMS_URL
  DRUPAL_SITE_DIR=$(_drupal_multisite_dir "$CMS_URL")
  if [ -n "$DRUPAL_SITE_DIR" -a -d "$WEB_ROOT/sites/$DRUPAL_SITE_DIR" ]; then
    rm -rf "$WEB_ROOT/sites/$DRUPAL_SITE_DIR"
  fi
}

###############################################################################
## Drupal Multi-Site -- Compute the name of the multi-site subdir
## Usage: _drupal_multisite_dir <url>
function _drupal_multisite_dir() {
  php -r '$p = parse_url($argv[1]); echo $p["port"] .".". $p["host"];' "$1"
}

###############################################################################
## Drupal Single-Site -- Generate config files and setup database
function drupal_singlesite_install() {
  cvutil_assertvars drupal_singlesite_install WEB_ROOT CMS_TITLE CMS_DB_USER CMS_DB_PASS CMS_DB_HOST CMS_DB_NAME ADMIN_USER ADMIN_PASS FACL_USERS

  pushd "$WEB_ROOT" >> /dev/null
    [ -f "sites/default/settings.php" ] && rm -f "sites/default/settings.php"

    drush site-install -y \
      --db-url="mysql://${CMS_DB_USER}:${CMS_DB_PASS}@${CMS_DB_HOST}/${CMS_DB_NAME}" \
      --account-name="$ADMIN_USER" \
      --account-pass="$ADMIN_PASS" \
      --account-mail="$ADMIN_EMAIL" \
      --site-name="$CMS_TITLE"
    chmod u+w "sites/default"

    ## Allow shell and WWW users to both manipulate "files" directory
    if which setfacl; then
      for FACL_USER in $FACL_USERS ; do
        find "$DRUPAL_ROOT/sites/default/files" -type d | xargs setfacl -m u:${FACL_USER}:rwx -m d:u:${FACL_USER}:rwx
      done
    fi

    ## Create Drupal-CiviCRM dirs and config
    for SUBDIR in modules files ; do
      if [ ! -d "sites/default/${SUBDIR}" ]; then
        mkdir "sites/default/${SUBDIR}"
      fi
    done
  popd >> /dev/null
}


###############################################################################
## Drupal Single-Site -- Destroy config files and database tables
function drupal_singlesite_uninstall() {
  cvutil_assertvars drupal_singlesite_uninstall WEB_ROOT
  pushd "$WEB_ROOT" >> /dev/null
    chmod u+w "sites/default"
    if [ -f "sites/default/settings.php" ]; then
      chmod u+w "sites/default/settings.php"
      rm -f "sites/default/settings.php"
    fi
    if [ -f "sites/default/files" ]; then
      chmod u+w "sites/default/files"
      rm -ff "sites/default/files"
    fi
  popd >> /dev/null
}

###############################################################################
## add hook shims to a repo
## usage: git_set_hooks <canonical-repo-name> <repo-path> <relative-hook-path>
function git_set_hooks() {
  GIT_CANONICAL_REPO_NAME="$1"
  TGT="$2"
  HOOK_DIR="$3"
  cvutil_assertvars  git_set_hooks GIT_CANONICAL_REPO_NAME TGT HOOK_DIR

  echo "[[Install recommended hooks ($TGT)]]"
  for HOOK in commit-msg post-checkout post-merge pre-commit prepare-commit-msg post-commit pre-rebase post-rewrite ;do
        cat << TMPL > "$TGT/.git/hooks/$HOOK"
#!/bin/bash
if [ -f "\$GIT_DIR/${HOOK_DIR}/${HOOK}" ]; then
  ## Note: GIT_CANONICAL_REPO_NAME was not provided by early hook-stubs
  export GIT_CANONICAL_REPO_NAME="$GIT_CANONICAL_REPO_NAME"
  source "\$GIT_DIR/${HOOK_DIR}/${HOOK}"
fi
TMPL
    chmod +x "$TGT/.git/hooks/$HOOK"
  done
}

###############################################################################
## Create or update the URL of a git remote
## usage: git_set_remote <local-repo-path> <remote-name> <remote-url>
function git_set_remote() {
  REPODIR="$1"
  REMOTE_NAME="$2"
  REMOTE_URL="$3"
  echo "[[Set remote ($REMOTE_NAME => $REMOTE_URL within $REPODIR)]]"

  pushd "$REPODIR" >> /dev/null
    git remote set-url "$REMOTE_NAME"  "$REMOTE_URL" >/dev/null 2>&1 || git remote add "$REMOTE_NAME"  "$REMOTE_URL"
  popd >> /dev/null
}
