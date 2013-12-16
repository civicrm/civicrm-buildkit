#!/bin/bash

## Bash helper functions

## Coding conventions:
## - Function names are "{prefix}_{name}"; prefixes are "util", "civicrm", "wp", etc
## - Options are set as (global) environment variables
## - Functions declare dependencies on (global) environment variables (util_assertvars).
##   If a variable missing, the application dies.

os_name=`uname -s | awk '{print tolower($0)}'`
os_specific_lib_path=src/civiprj.lib.$os_name.sh
if [ -e $os_specific_lib_path ]; then
  source $os_specific_lib_path
fi

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
  cvutil_assertvars civicrm_make_settings_php CMS_DB_HOST CMS_DB_PORT CMS_DB_NAME CMS_DB_PASS CMS_DB_USER
  cvutil_assertvars civicrm_make_settings_php CIVI_DB_HOST CMS_DB_PORT CIVI_DB_NAME CIVI_DB_PASS CIVI_DB_USER

  cat "$CIVI_CORE/templates/CRM/common/civicrm.settings.php.template" \
    | sed "s;%%baseURL%%;${CMS_URL};" \
    | sed "s;%%cms%%;${CIVI_UF};" \
    | sed "s;%%CMSdbHost%%;${CMS_DB_HOST};" \
    | sed "s;%%CMSdbPort%%;${CMS_DB_PORT};" \
    | sed "s;%%CMSdbName%%;${CMS_DB_NAME};" \
    | sed "s;%%CMSdbPass%%;${CMS_DB_PASS};" \
    | sed "s;%%CMSdbUser%%;${CMS_DB_USER};" \
    | sed "s;%%crmRoot%%;${CIVI_CORE}/;" \
    | sed "s;%%dbHost%%;${CIVI_DB_HOST};" \
    | sed "s;%%dbPort%%;${CIVI_DB_PORT};" \
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
  cvutil_assertvars civicrm_make_setup_conf CIVI_CORE CIVI_UF CIVI_DB_NAME CIVI_DB_USER CIVI_DB_PASS CIVI_DB_HOST CIVI_DB_PORT

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
  cvutil_assertvars civicrm_make_test_settings_php CIVI_CORE CIVI_DB_NAME CIVI_DB_USER CIVI_DB_PASS CIVI_DB_HOST CIVI_DB_PORT WEB_ROOT CMS_URL ADMIN_USER ADMIN_PASS DEMO_USER DEMO_PASS CIVI_SITE_KEY

  ## TODO: REVIEW
  cat > "$CIVI_CORE/tests/phpunit/CiviTest/civicrm.settings.local.php" << EOF
<?php
  define('CIVICRM_DSN', "mysql://${CIVI_DB_USER}:${CIVI_DB_PASS}@${CIVI_DB_HOST}:${CIVI_DB_PORT}/${CIVI_DB_NAME}");
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
        find "$WEB_ROOT/sites/${DRUPAL_SITE_DIR}/files" -type d | xargs setfacl -m u:${FACL_USER}:rwx -m d:u:${FACL_USER}:rwx
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
      --db-url="mysql://${CMS_DB_USER}:${CMS_DB_PASS}@${CMS_DB_HOST}:${CMS_DB_PORT}/${CMS_DB_NAME}" \
      --account-name="$ADMIN_USER" \
      --account-pass="$ADMIN_PASS" \
      --account-mail="$ADMIN_EMAIL" \
      --site-name="$CMS_TITLE"
    chmod u+w "sites/default"

    ## Allow shell and WWW users to both manipulate "files" directory
    if which setfacl; then
      for FACL_USER in $FACL_USERS ; do
        find "$WEB_ROOT/sites/default/files" -type d | xargs setfacl -m u:${FACL_USER}:rwx -m d:u:${FACL_USER}:rwx
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

function civiprj_create() {
  echo "[[Create $SITE_NAME (type '$SITE_TYPE' in '$WEB_ROOT')]]"

  if [ -n "$FORCE_DOWNLOAD" -a -d "$WEB_ROOT" ]; then
    rm -rf "$WEB_ROOT"
  fi

  if [ -n "$MYSQL_RAM_SERVER" ]; then
    mysql_setup_ram_server
  fi

  if [ ! -d "$WEB_ROOT" ]; then
    pushd "$PRJDIR" > /dev/null
    civiprj_run download
    popd > /dev/null
    if [ ! -d "$WEB_ROOT" ]; then
      echo "Download failed to create directory"
      exit 97
    fi
  fi

  if [ -n "$FORCE_INSTALL" -a -n "$CMS_DB_DSN" ]; then
    pushd "$WEB_ROOT" > /dev/null
    civiprj_run uninstall
    popd > /dev/null
  fi

  if [ -n "$FORCE_INSTALL" -o -z "$CMS_DB_DSN" ]; then
    pushd "$WEB_ROOT" > /dev/null
    civiprj_run install
    popd > /dev/null

    if [ -n "$CIVI_SQL" ]; then
      cvutil_makeparent "$CIVI_SQL"
      mysqldump -h "$CIVI_DB_HOST" -P "$CIVI_DB_PORT" -u"$CIVI_DB_USER" -p"$CIVI_DB_PASS" "$CIVI_DB_NAME" | gzip > $CIVI_SQL
    fi

    if [ -n "$CMS_SQL" ]; then
      cvutil_makeparent "$CMS_SQL"
      mysqldump -h "$CMS_DB_HOST" -P "$CMS_DB_PORT" -u"$CMS_DB_USER" -p"$CMS_DB_PASS" "$CMS_DB_NAME" | gzip > $CMS_SQL
    fi
  fi
  cvutil_save "${BLDDIR}/${SITE_NAME}.sh" $PERSISTENT_VARS
}

function civiprj_run_tests() {
  if [ -n "$MYSQL_RAM_SERVER" ]; then
    mysql_setup_ram_server
  fi
  civiprj_create
  pushd $CIVI_CORE > /dev/null
  ./tools/scripts/phpunit AllTests
  popd > /dev/null
}

function mysql_setup_ram_server() {
  setup_ram_disk

  if [ $CIVI_DB_PORT -eq 3306 ]; then
    CIVI_DB_PORT=3307
    if [ $CMS_DB_PORT -eq 3306 ]; then
      CMS_DB_PORT=$CIVI_DB_PORT
    fi
  fi

  if [ "$CIVI_DB_HOST" = "localhost" ]; then
    CIVI_DB_HOST="127.0.0.1"
  fi

  if [ "$CMS_DB_HOST" = "localhost" ]; then
    CMS_DB_HOST="127.0.0.1"
  fi

  if [ "$CIVI_DB_HOST" != "127.0.0.1" -o "$CMS_DB_HOST" != "127.0.0.1" ]; then
    echo "You can't use the mysql ram server with anything but localhost (127.0.0.1), so you must set both CIVI_DB_HOST and CMS_DB_HOST to 127.0.0.1"
    exit 255
  fi

  mysql_data_dir=$TMPFS_DIR/mysql
  if [ ! -d $mysql_data_dir ]; then
    mkdir -p $mysql_data_dir
  fi

  mysql_system_dir=$mysql_data_dir/mysql
  if [ ! -d $mysql_system_dir ]; then
    mkdir -p $mysql_system_dir
  fi

  socket_file_path=$TMPFS_DIR/mysqld.sock
  pid_file_path=$TMPFS_DIR/mysqld.pid
  install_command_file=$TMPDIR/install_mysql.sql

  if [ ! -e $socket_file_path ]; then
    echo "use mysql;" > $install_command_file
    cat /usr/share/mysql/mysql_system_tables.sql /usr/share/mysql/mysql_system_tables_data.sql >> $install_command_file
    mysqld_base_command="mysqld --no-defaults --tmpdir=/tmp --datadir=$mysql_data_dir --port=$CIVI_DB_PORT --socket=$socket_file_path --pid-file=$pid_file_path"
    $mysqld_base_command --log-warnings=0 --bootstrap --loose-skip-innodb --max_allowed_packet=8M --default-storage-engine=myisam --net_buffer_length=16K < $install_command_file
    $mysqld_base_command > $TMPDIR/$SITE_NAME-mysql.log 2>&1 &
    i=0
    while [ ! -e $socket_file_path -a $i -lt 10 ]; do
      i=$((i+1));
      sleep 1
    done
    mysqladmin --socket=$socket_file_path --user=root --password='' password 'foobar'
    cat > $install_command_file <<EOF
CREATE USER '$CIVI_DB_USER'@'127.0.0.1' IDENTIFIED BY '$CIVI_DB_PASS';
GRANT ALL PRIVILEGES ON *.* TO '$CIVI_DB_USER'@'127.0.0.1' WITH GRANT OPTION;
EOF
    echo $install_command_file
    mysql --socket=$socket_file_path --user=root --password='foobar' < $install_command_file
  fi
}
