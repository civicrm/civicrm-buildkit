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
## Export environment variables for use by a sub-process
## usage: cvutil_export() <var1> <var2> ...
function cvutil_export() {
  for var in "$@" ; do
    export $var
  done
}

###############################################################################
## Summarize the content of key environment variables
## usage: cvutil_summary <message> <var1> <var2> ...
function cvutil_summary() {
  if [ -n "$1" ]; then
    echo $1
  fi
  shift

  cvutil_assertvars cvutil_summary "$@"
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
## Ensure that a directory exists
## cvutil_mkdir <dir1> <dir2> ...
function cvutil_mkdir() {
  for f in "$@" ; do
    if [ ! -d "$f" ]; then
      mkdir "$f"
    fi
  done
}

###############################################################################
## Combine host and port to a single string
## usage: MY_VAR=$(cvutil_build_hostport $MY_HOST $MY_PORT )
function cvutil_build_hostport() {
  local host=$1
  local port=$2
  if [ -z "$port" ]; then
    echo "$host"
  else
    echo "$host:$port"
  fi
}

###############################################################################
## Parse the name and ID from
## usage: eval $(cvutil_parse_site_name_id "NAME[/ID]")
## example: $(cvutil_parse_site_name_id "drupal-demo/2") ==> SITE_NAME=drupal-demo SITE_ID=2
## example: $(cvutil_parse_site_name_id "drupal-demo") ==> SITE_NAME=drupal-demo
function cvutil_parse_site_name_id() {
  php -r '$parts=explode("/", $argv[1]);echo "SITE_NAME=" . $parts[0]."\n"; if (isset($parts[1])) echo "SITE_ID=" . $parts[1] . "\n";' "$1"
}

###############################################################################
## Append the civibuild settings directives to a file
## usage: cvutil_append_settings <php-file> <settings-dir-name>
## example: cvutil_append_settings "/var/www/build/drupal/sites/foo/civicrm.settings.php" "civicrm.settings.d"
## example: cvutil_append_settings "/var/www/build/drupal/sites/foo/settings.php" "drupal.settings.d"
function cvutil_append_settings() {
  local FILE="$1"
  local NAME="$2"
  cvutil_assertvars cvutil_append_settings PRJDIR SITE_NAME SITE_TYPE SITE_CONFIG_DIR SITE_ID PRIVATE_ROOT FILE NAME
  cat >> "$FILE" << EOF
    global \$civibuild;
    \$civibuild['PRJDIR'] = '$PRJDIR';
    \$civibuild['SITE_CONFIG_DIR'] = '$SITE_CONFIG_DIR';
    \$civibuild['SITE_TYPE'] = '$SITE_TYPE';
    \$civibuild['SITE_NAME'] = '$SITE_NAME';
    \$civibuild['SITE_ID'] = '$SITE_ID';
    \$civibuild['PRIVATE_ROOT'] = '$PRIVATE_ROOT';
    \$civibuild['WEB_ROOT'] = '$WEB_ROOT';
    \$civibuild['CMS_ROOT'] = '$CMS_ROOT';

    if (file_exists(\$civibuild['PRJDIR'].'/src/civibuild.settings.php')) {
      require_once \$civibuild['PRJDIR'].'/src/civibuild.settings.php';
      _civibuild_settings(__FILE__, '$NAME', \$civibuild);
    }
EOF
}

###############################################################################
## Setup HTTP and MySQL services
## This outputs several variables: CMS_URL, CMS_DB_*, CIVI_DB_*, and TEST_DB_*
function amp_install() {
  ## TODO: single-db support
  _amp_install_cms
  _amp_install_civi
  _amp_install_test
}

function _amp_install_cms() {
  echo "[[Setup MySQL and HTTP for CMS]]"
  cvutil_assertvars _amp_install_cms CMS_ROOT SITE_NAME SITE_ID TMPDIR
  local amp_vars_file_path="${TMPDIR}/${SITE_NAME}-amp-vars.sh"
  local amp_name="cms$SITE_ID"
  [ "$SITE_ID" == "default" ] && amp_name=cms

  if [ -n "$CMS_URL" ]; then
    amp create -f --root="$CMS_ROOT" --name="$amp_name" --prefix=CMS_ --url="$CMS_URL" --output-file="$amp_vars_file_path"
  else
    amp create -f --root="$CMS_ROOT" --name="$amp_name" --prefix=CMS_ --output-file="$amp_vars_file_path"
  fi

  source "$amp_vars_file_path"
}

function _amp_install_civi() {
  echo "[[Setup MySQL for Civi]]"
  cvutil_assertvars _amp_install_civi CMS_ROOT SITE_NAME SITE_ID TMPDIR
  local amp_vars_file_path="${TMPDIR}/${SITE_NAME}-amp-vars.sh"
  local amp_name="civi$SITE_ID"
  [ "$SITE_ID" == "default" ] && amp_name=civi

  amp create -f --root="$CMS_ROOT" --name="$amp_name" --prefix=CIVI_ --skip-url --output-file="$amp_vars_file_path" --perm=super

  source "$amp_vars_file_path"
}

function _amp_install_test() {
  echo "[[Setup MySQL for Test]]"
  cvutil_assertvars _amp_install_test CMS_ROOT SITE_NAME SITE_ID TMPDIR
  local amp_vars_file_path="${TMPDIR}/${SITE_NAME}-amp-vars.sh"
  local amp_name="test$SITE_ID"
  [ "$SITE_ID" == "default" ] && amp_name=test

  amp create -f --root="$CMS_ROOT" --name="$amp_name" --prefix=TEST_ --skip-url --output-file="$amp_vars_file_path" --perm=super

  source "$amp_vars_file_path"
}

###############################################################################
## Backup the databases & http config (using the same structure as amp_install)
function amp_snapshot_create() {
  ## TODO: single-db support

  if [ -z "$CMS_SQL_SKIP" ]; then
    echo "[[Save CMS DB ($CMS_DB_NAME) to file ($CMS_SQL)]]"
    cvutil_assertvars amp_snapshot_create CMS_SQL CMS_DB_ARGS CMS_DB_NAME
    cvutil_makeparent "$CMS_SQL"
    mysqldump $CMS_DB_ARGS | gzip > "$CMS_SQL"
  fi

  if [ -z "$CIVI_SQL_SKIP" ]; then
    echo "[[Save Civi DB ($CIVI_DB_NAME) to file ($CIVI_SQL)]]"
    cvutil_assertvars amp_snapshot_create CIVI_SQL CIVI_DB_ARGS CIVI_DB_NAME
    cvutil_makeparent "$CIVI_SQL"
    mysqldump $CIVI_DB_ARGS | gzip > "$CIVI_SQL"
  fi
}

###############################################################################
## Restore the databases & http config (using the same structure as amp_install)
function amp_snapshot_restore() {
  ## TODO: single-db support

  if [ -z "$CMS_SQL_SKIP" ]; then
    _amp_snapshot_restore_cms
  fi

  if [ -z "$CIVI_SQL_SKIP" ]; then
    _amp_snapshot_restore_civi
  fi

  if [ -z "$TEST_SQL_SKIP" ]; then
    _amp_snapshot_restore_test
  fi
}

function _amp_snapshot_restore_cms() {
  local orig_CMS_DB_ARGS="$CMS_DB_ARGS"
  _amp_install_cms
  if [ "$CMS_DB_ARGS" != "$orig_CMS_DB_ARGS" ]; then
    ## shouldn't happen unless someone has been mucking around...
    echo "WARNING: CMS DB has changed! Config files may be stale!" > /dev/stderr
    echo "  OLD: $orig_CMS_DB_ARG" > /dev/stderr
    echo "  NEW: $CMS_DB_ARGS" > /dev/stderr
  fi

  echo "[[Restore CMS DB ($CMS_DB_NAME) from file ($CMS_SQL)]]"
  cvutil_assertvars amp_snapshot_restore CMS_SQL CMS_DB_ARGS CMS_DB_NAME
  if [ ! -f "$CMS_SQL" ]; then
    echo "Missing SQL file: $CMS_SQL" >> /dev/stderr
    exit 1
  fi
  gunzip --stdout "$CMS_SQL" | mysql $CMS_DB_ARGS
}

function _amp_snapshot_restore_civi() {
  local orig_CIVI_DB_ARGS="$CIVI_DB_ARGS"
  _amp_install_civi
  if [ "$CIVI_DB_ARGS" != "$orig_CIVI_DB_ARGS" ]; then
    ## shouldn't happen unless someone has been mucking around...
    echo "WARNING: Civi DB has changed! Config files may be stale!" > /dev/stderr
    echo "  OLD: $orig_CIVI_DB_ARG" > /dev/stderr
    echo "  NEW: $CIVI_DB_ARGS" > /dev/stderr
  fi

  echo "[[Restore Civi DB ($CIVI_DB_NAME) from file ($CIVI_SQL)]]"
  cvutil_assertvars amp_snapshot_restore CIVI_SQL CIVI_DB_ARGS CIVI_DB_NAME
  if [ ! -f "$CIVI_SQL" ]; then
    echo "Missing SQL file: $CIVI_SQL" >> /dev/stderr
    exit 1
  fi
  gunzip --stdout "$CIVI_SQL" | mysql $CIVI_DB_ARGS
}

function _amp_snapshot_restore_test() {
  local orig_TEST_DB_ARGS="$TEST_DB_ARGS"
  _amp_install_test
  if [ "$TEST_DB_ARGS" != "$orig_TEST_DB_ARGS" ]; then
    ## shouldn't happen unless someone has been mucking around...
    echo "WARNING: TEST DB has changed! Config files may be stale!" > /dev/stderr
    echo "  OLD: $orig_TEST_DB_ARG" > /dev/stderr
    echo "  NEW: $TEST_DB_ARGS" > /dev/stderr
  fi
  echo "[[Restore Test DB ($TEST_DB_NAME) from file ($CIVI_SQL)]]"
  cvutil_assertvars amp_snapshot_restore CIVI_SQL TEST_DB_ARGS TEST_DB_NAME
  if [ ! -f "$CIVI_SQL" ]; then
    echo "Missing SQL file: $CIVI_SQL" >> /dev/stderr
    exit 1
  fi
  gunzip --stdout "$CIVI_SQL" | mysql -o $TEST_DB_ARGS

}

###############################################################################
## Tear down HTTP and MySQL services
function amp_uninstall() {
  echo "WARNING: amp_uninstall: Retaining DB & site config to provide continuity among rebuilds"
}

###############################################################################
## Generate config files and setup database
function civicrm_install() {
  cvutil_assertvars civicrm_install CIVI_CORE CIVI_FILES CIVI_TEMPLATEC CIVI_DOMAIN_NAME CIVI_DOMAIN_EMAIL

  if [ ! -d "$CIVI_CORE/bin" -o ! -d "$CIVI_CORE/CRM" ]; then
    echo "Failed to locate valid civi root: $CIVI_CORE"
    exit 1
  fi

  ## Create CiviCRM data dirs
  amp datadir "$CIVI_FILES" "$CIVI_TEMPLATEC"
  if [ -n "$CIVI_EXT_DIR" ]; then
    amp datadir "$CIVI_EXT_DIR"
  fi

  ## Create CiviCRM config files
  civicrm_make_settings_php
  civicrm_make_setup_conf
  civicrm_make_test_settings_php

  pushd "$CIVI_CORE" >> /dev/null
    ## Does this build include development support (eg git or tarball-based)?
    if [ -e "xml" -a -e "bin/setup.sh" ]; then
      ./bin/setup.sh
    elif [ -e "sql/civicrm.mysql" -a -e "sql/civicrm_generated.mysql" ]; then
      cat sql/civicrm.mysql sql/civicrm_generated.mysql | mysql $CIVI_DB_ARGS
    else
      echo "Failed to locate civi SQL files"
    fi
  popd >> /dev/null

  mysql $CIVI_DB_ARGS <<EOSQL
    UPDATE civicrm_domain SET name = '$CIVI_DOMAIN_NAME';
    SELECT @option_group_id := id
      FROM civicrm_option_group n
      WHERE name = 'from_email_address';
    UPDATE civicrm_option_value
      SET label = '$CIVI_DOMAIN_EMAIL'
      WHERE option_group_id = @option_group_id
      AND value = '1';
EOSQL
}

###############################################################################
## Generate a "civicrm.settings.php" file
function civicrm_make_settings_php() {
  cvutil_assertvars civicrm_make_settings_php CIVI_SETTINGS CIVI_CORE CIVI_UF CIVI_TEMPLATEC CMS_URL CIVI_SITE_KEY
  cvutil_assertvars civicrm_make_settings_php CMS_DB_HOST CMS_DB_NAME CMS_DB_PASS CMS_DB_USER
  cvutil_assertvars civicrm_make_settings_php CIVI_DB_HOST CIVI_DB_NAME CIVI_DB_PASS CIVI_DB_USER
  cvutil_assertvars civicrm_make_settings_php SITE_CONFIG_DIR

  local tpl
  for tpl in templates/CRM/common/civicrm.settings.php.template templates/CRM/common/civicrm.settings.php.tpl ; do
    if [ -f "$CIVI_CORE/$tpl" ]; then
      break
    fi
  done
  if [ ! -f "$CIVI_CORE/$tpl" ]; then
    echo "Failed to locate template for civicrm.settings.php"
    exit 96
  fi

  CMS_DB_HOSTPORT=$(cvutil_build_hostport "$CMS_DB_HOST" "$CMS_DB_PORT")
  CIVI_DB_HOSTPORT=$(cvutil_build_hostport "$CIVI_DB_HOST" "$CIVI_DB_PORT")
  cat "$CIVI_CORE/$tpl" \
    | sed "s;%%baseURL%%;${CMS_URL};" \
    | sed "s;%%cms%%;${CIVI_UF};" \
    | sed "s;%%CMSdbHost%%;${CMS_DB_HOSTPORT};" \
    | sed "s;%%CMSdbName%%;${CMS_DB_NAME};" \
    | sed "s;%%CMSdbPass%%;${CMS_DB_PASS};" \
    | sed "s;%%CMSdbUser%%;${CMS_DB_USER};" \
    | sed "s;%%crmRoot%%;${CIVI_CORE}/;" \
    | sed "s;%%dbHost%%;${CIVI_DB_HOSTPORT};" \
    | sed "s;%%dbName%%;${CIVI_DB_NAME};" \
    | sed "s;%%dbPass%%;${CIVI_DB_PASS};" \
    | sed "s;%%dbUser%%;${CIVI_DB_USER};" \
    | sed "s;%%siteKey%%;${CIVI_SITE_KEY};" \
    | sed "s;%%templateCompileDir%%;${CIVI_TEMPLATEC};" \
    > "$CIVI_SETTINGS"
  echo >> "$CIVI_SETTINGS"

  if [ -n "$CIVI_EXT_DIR" ]; then
    cat >> "$CIVI_SETTINGS" << EOF
    global \$civicrm_setting;
    \$civicrm_setting['Directory Preferences']['extensionsDir'] = '$CIVI_EXT_DIR';
    \$civicrm_setting['URL Preferences']['extensionsURL'] = '$CIVI_EXT_URL';
EOF
  fi

  cvutil_append_settings "$CIVI_SETTINGS" "civicrm.settings.d"
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
    DBHOST="$CIVI_DB_HOST"
    DBPORT="$CIVI_DB_PORT"
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
  cvutil_assertvars civicrm_make_test_settings_php CIVI_CORE CIVI_DB_NAME CIVI_DB_USER CIVI_DB_PASS CIVI_DB_HOST CMS_URL ADMIN_USER ADMIN_PASS DEMO_USER DEMO_PASS CIVI_SITE_KEY

  ## Does this build include development support (eg git or tarball-based)?
  if [ -d "$CIVI_CORE/tests/phpunit/CiviTest" ]; then
    ## TODO: REVIEW
    cat > "$CIVI_CORE/tests/phpunit/CiviTest/civicrm.settings.local.php" << EOF
<?php
  if (defined('CIVICRM_WEBTEST')) {
    // For Selenium tests, use normal DB
    define('CIVICRM_DSN', "mysql://${CIVI_DB_USER}:${CIVI_DB_PASS}@${CIVI_DB_HOST}:${CIVI_DB_PORT}/${CIVI_DB_NAME}");
  } else {
    // For unit tests, use headless test DB
    define('CIVICRM_DSN', "mysql://${TEST_DB_USER}:${TEST_DB_PASS}@${TEST_DB_HOST}:${TEST_DB_PORT}/${TEST_DB_NAME}");
  }
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
  fi
}

###############################################################################
## Generate config files and setup database
function wp_install() {
  cvutil_assertvars wp_install CMS_ROOT CMS_DB_NAME CMS_DB_USER CMS_DB_PASS CMS_DB_HOST CMS_URL ADMIN_USER ADMIN_PASS ADMIN_EMAIL CMS_TITLE

  CMS_DB_HOSTPORT=$(cvutil_build_hostport $CMS_DB_HOST $CMS_DB_PORT)
  pushd "$CMS_ROOT" >> /dev/null
    [ -f "wp-config.php" ] && rm -f "wp-config.php"
    wp core config \
      --dbname="$CMS_DB_NAME" \
      --dbuser="$CMS_DB_USER" \
      --dbpass="$CMS_DB_PASS" \
      --dbhost="$CMS_DB_HOSTPORT" \
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
    cvutil_mkdir "wp-content/plugins/modules"
    amp datadir "wp-content/plugins/files"

    cvutil_append_settings "wp-config.php" "wp-config.d"
  popd >> /dev/null
}

###############################################################################
## Destroy config files and database tables
function wp_uninstall() {
  cvutil_assertvars wp_uninstall CMS_ROOT
  pushd "$CMS_ROOT" >> /dev/null
    [ -f "wp-config.php" ] && rm -f "wp-config.php"
    [ -f "wp-content/plugins/files" ] && rm -rf "wp-content/plugins/files"
  popd >> /dev/null
}

###############################################################################
## Drupal -- Generate config files and setup database
## usage: drupal_install <extra-drush-args>
## To use an "install profile", simply pass it as part of <extra-drush-args>
function drupal_install() {
  cvutil_assertvars drupal_install CMS_ROOT SITE_ID CMS_TITLE CMS_DB_USER CMS_DB_PASS CMS_DB_HOST CMS_DB_NAME ADMIN_USER ADMIN_PASS CMS_URL
  DRUPAL_SITE_DIR=$(_drupal_multisite_dir "$CMS_URL" "$SITE_ID")
  CMS_DB_HOSTPORT=$(cvutil_build_hostport "$CMS_DB_HOST" "$CMS_DB_PORT")
  pushd "$CMS_ROOT" >> /dev/null
    [ -f "sites/$DRUPAL_SITE_DIR/settings.php" ] && rm -f "sites/$DRUPAL_SITE_DIR/settings.php"

    drush site-install -y "$@" \
      --db-url="mysql://${CMS_DB_USER}:${CMS_DB_PASS}@${CMS_DB_HOSTPORT}/${CMS_DB_NAME}" \
      --account-name="$ADMIN_USER" \
      --account-pass="$ADMIN_PASS" \
      --account-mail="$ADMIN_EMAIL" \
      --site-name="$CMS_TITLE" \
      --sites-subdir="$DRUPAL_SITE_DIR"
    chmod u+w "sites/$DRUPAL_SITE_DIR"
    chmod u+w "sites/$DRUPAL_SITE_DIR/settings.php"
    cvutil_append_settings "$CMS_ROOT/sites/$DRUPAL_SITE_DIR/settings.php" "drupal.settings.d"
    chmod u-w "sites/$DRUPAL_SITE_DIR/settings.php"

    ## Setup extra directories
    amp datadir "sites/${DRUPAL_SITE_DIR}/files" "${PRIVATE_ROOT}/${DRUPAL_SITE_DIR}"
    cvutil_mkdir "sites/${DRUPAL_SITE_DIR}/modules"
    drush vset --yes file_private_path "${PRIVATE_ROOT}/${DRUPAL_SITE_DIR}"
  popd >> /dev/null
}

###############################################################################
## Drupal -- Destroy config files and database tables
function drupal_uninstall() {
  cvutil_assertvars drupal_uninstall CMS_ROOT SITE_ID CMS_URL
  DRUPAL_SITE_DIR=$(_drupal_multisite_dir "$CMS_URL" "$SITE_ID")

  if [ -n "$DRUPAL_SITE_DIR" -a -d "$CMS_ROOT/sites/$DRUPAL_SITE_DIR" ]; then
    if [ "$SITE_ID" == "default" ]; then
      ## For default site, carfully pick files to delete.
      ## Need to keep default.settings.php.
      pushd "$CMS_ROOT" >> /dev/null
        chmod u+w "sites/default"
        if [ -f "sites/default/settings.php" ]; then
          chmod u+w "sites/default/settings.php"
          rm -f "sites/default/settings.php"
        fi
        if [ -f "sites/default/files" ]; then
          chmod u+w "sites/default/files"
          rm -f "sites/default/files"
        fi
      popd >> /dev/null
    else
      rm -rf "$CMS_ROOT/sites/$DRUPAL_SITE_DIR"
    fi
  fi

  if [ -n "$DRUPAL_SITE_DIR" -a -d "$PRIVATE_ROOT/$DRUPAL_SITE_DIR" ]; then
    rm -rf "$PRIVATE_ROOT/$DRUPAL_SITE_DIR"
  fi
}

###############################################################################
## Drupal -- Compute the name of the multi-site subdir
## Usage: _drupal_multisite_dir <url> <site-id>
## Note: <site-id> is 0 for the default/base site
function _drupal_multisite_dir() {
  if [ "$2" == "default" ]; then
    echo "default"
  else
    php -r '$p = parse_url($argv[1]); if (!empty($p["port"])) echo $p["port"] . "."; echo $p["host"];' "$1"
  fi
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

###############################################################################
## Initialize (or update) a cached copy of a git repo in $CACHE_DIR
## usage: git_cache_setup <url> <cache-dir>
function git_cache_setup() {
  local url="$1"
  local cachedir="$2"
  local lock="${cachedir}.lock"
  local lastrun="${cachedir}.lastrun"
  ## TODO: defensive programming: $cachedir should not end in "/"

  if [ -d "$cachedir" -a -f "$lastrun" -a -z "$FORCE_DOWNLOAD" ]; then
    if php -r 'exit($argv[1] + file_get_contents($argv[2]) < time() ? 1 : 0);' $CACHE_TTL "$lastrun" ; then
      echo "SKIP: git_cache_setup '$url' $cachedir' (recently updated; ttl=$CACHE_TTL)"
      return
    fi
  fi

  cvutil_makeparent "$lock"
  if pidlockfile.php "$lock" $$ $CACHE_LOCK_WAIT ; then
    php -r 'echo time();' > $lastrun
    if [ ! -d "$cachedir" ]; then
      ## clone
      echo "[[Initialize cache dir: $cachedir]]"
      cvutil_makeparent "$cachedir"
      git clone --mirror "$url" "$cachedir"
    else
      ## update
      pushd "$cachedir" >> /dev/null
        git remote set-url origin "$url"
        git fetch origin
      popd >> /dev/null
    fi

    rm -f "$lock"
  else
    echo "ERROR: git_cache_setup '$url' '$cachdir': failed to acquire lock"
  fi
}

###############################################################################
## Fix the remote configurations of any git repos in <build-dir>, changing any
## references to <cache-base-dir> to proper remotes
## usage: git_cache_deref_remotes <cache-base-dir> <build-dir>
function git_cache_deref_remotes() {
  local _shellopt="$-"
  set +x

  local cachedir="$1"
  local builddir="$2"
  find "$builddir" -type d -name .git | while read gitdir; do
    pushd "$gitdir" >> /dev/null
      pushd ".." >> /dev/null
        local origin_old=$(git config --get remote.origin.url)
        if [[ $origin_old == ${cachedir}* || $origin_old == file://${cachedir}* || $origin_old == file:///${cachedir}*  ]]; then
          local origin_path=$(echo "$origin_old" | sed 's;file://;;')
          pushd "$origin_path" >> /dev/null
            origin_new=$(git config --get remote.origin.url)
          popd >> /dev/null
          echo "Change origin in [$gitdir] from [$origin_old] to [$origin_new]"
          git remote set-url origin "$origin_new"
          git fetch origin
        fi
      popd >> /dev/null
    popd >> /dev/null
  done

  set -${_shellopt}
}

###############################################################################
## Initialize (or update) a cached copy of an svn URL
## usage: svn_cache_setup <url> <cache-dir>
function svn_cache_setup() {
  local url="$1"
  local cachedir="$2"
  local lock="${cachedir}.lock"
  local lastrun="${cachedir}.lastrun"
  ## TODO: defensive programming: $cachedir should not end in "/"

  if [ -d "$cachedir" -a -f "$lastrun" -a -z "$FORCE_DOWNLOAD" ]; then
    if php -r 'exit($argv[1] + file_get_contents($argv[2]) < time() ? 1 : 0);' $CACHE_TTL "$lastrun" ; then
      echo "SKIP: svn_cache_setup '$url' $cachedir' (recently updated; ttl=$CACHE_TTL)"
      return
    fi
  fi

  cvutil_makeparent "$lock"
  if pidlockfile.php "$lock" $$ $CACHE_LOCK_WAIT ; then
    php -r 'echo time();' > $lastrun
    if [ ! -d "$cachedir" ]; then
      ## clone
      echo "[[Initialize cache dir: $cachedir]]"
      cvutil_makeparent "$cachedir"
      svn co "$url" "$cachedir"
    else
      ## update
      pushd "$cachedir" >> /dev/null
        svn up
      popd >> /dev/null
    fi

    rm -f "$lock"
  else
    echo "ERROR: svn_cache_setup '$url' '$cachedir': failed to acquire lock"
  fi
}

###############################################################################
## Setup an SVN working copy from a previously cached URL
## usage: svn_cache_clone <cache-dir> <new-working-dir>
function svn_cache_clone() {
  local cachedir="$1"
  local workdir="$2"
  if [ ! -d "$workdir" ]; then
    cvutil_makeparent "$workdir"
    cvutil_mkdir "$workdir"
  fi
  rsync -va "$cachedir/./" "$workdir/./"
}
