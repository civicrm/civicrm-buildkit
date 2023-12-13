#!/usr/bin/env bash

## Bash helper functions

## Coding conventions:
## - Function names are "{prefix}_{name}"; prefixes are "cvutil", "civicrm", "wp", etc
## - Options are set as (global) environment variables
## - Functions declare dependencies on (global) environment variables (cvutil_assertvars).
##   If a variable missing, the application dies.

###############################################################################
## Assert that shell variables are defined. If not defined, exit with an error.
## usage: assertvars <context> <var1> <var2> <var3> ...
## exmple: cvutil_assertvars civibuild_app_download WEB_ROOT PRJDIR CACHE_DIR SITE_NAME SITE_TYPE
function cvutil_assertvars() {
  _cvutil_assertvars_back="$-"

  # disable verbose output:
  set +x

  # the calling function name:
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

  #restore previous bash options (revert set +x)
  set -${_cvutil_assertvars_back}
}

###############################################################################
## Run a PHP program and explicitly disable debugging.
## usage: cvutil_php_nodbg <program name> [<args>...]
function cvutil_php_nodbg() {
  local cmd=$(which "$1")
  [ -z "$cmd" ] && cvutil_fatal "Failed to locate $cmd"
  shift
  XDEBUG_PORT= XDEBUG_MODE=off php -d xdebug.remote_enable=off "$cmd" "$@"
}

###############################################################################
## Find the location of <item> in a list of paths.
## usage: cvutil_path_search <item> <parent1>:<parent2>:...
## example: cvutil_path_search ls /usr/local/bin:/usr/bin:/bin
function cvutil_path_search() {
  local search_target="$1"
  local search_paths="$2"
  printf %s "$search_paths" | awk 'BEGIN {RS=":"}; 1' | while read candidate ; do
    if [ -n "$candidate" -a -e "$candidate/$search_target" ]; then
      echo "$candidate/$search_target"
      break
    fi
  done
}

###############################################################################
## Prompt user for confirmation
## (In automated scripts or blank response, use default)
##
## usage: cvutil_confirm <message> <interactive-default> <script-default>
## example: cvutil_confirm "Are you sure? [Y/n] " y y
function cvutil_confirm() {
  local msg="$1"
  local i_default="$2"
  local s_default="$3"
  if tty -s ; then
    echo -n "$msg"
    read _cvutil_confirm
    if [ "x$_cvutil_confirm" == "x" ]; then
      _cvutil_confirm="$i_default"
    fi
  else
    echo "${msg}${s_default}"
    _cvutil_confirm="$s_default"
  fi
  case "$_cvutil_confirm" in
    y|Y|1)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

###############################################################################
## Save a list of environment variables to a file
## usage: cvutil_save() <filename> <var1> <var2> ...
function cvutil_save() {
  file="$1"
  shift

  echo "#!/usr/bin/env bash" > $file
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
##  usage: cvutil-fatal <message>
function cvutil_fatal() {
  echo "$@" >&2
  exit 90
}

###############################################################################
## Delete a file try, overriding any unwriteable file permissions
function cvutil_rmrf() {
  local folder="$1"
  if [ -z "$folder" ]; then
    return
  fi
  if [ ! -e "$folder" ]; then
    return
  fi
  find "$folder" -type d -print0 | xargs -0 -n 20 chmod u+w
  rm -rf "$folder"
}

###############################################################################
## Summarize the content of key environment variables
## usage: cvutil_summary <message> <var1> <var2> ...
function cvutil_summary() {
# Not asserting any vars because then we can't report that they are in fact empty.
  if [ -n "$1" ]; then
    echo $1
  fi
  shift

  for var in "$@" ; do
    eval "val=\$$var"
    echo " - $var: $val"
  done
}


###############################################################################
## usage: cvutil_makepasswd <strlen>
function cvutil_makepasswd() {
  cvutil_php_nodbg mkpasswd.php "$@"
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
      mkdir -p "$f"
    fi
  done
}

###############################################################################
## Compose a new URL For a site
## Usage: myurl=$(cvutil_mkurl <shortname>)
function cvutil_mkurl() {
  local subsite_name="$1"
  cvutil_assertvars cvutil_mkurl URL_TEMPLATE
  if [ "%AUTO%" == "$URL_TEMPLATE" ]; then
    echo "http://%subsite_name%.test" | sed "s;%SITE_NAME%;$subsite_name;g"
  else
    echo "$URL_TEMPLATE" | sed "s;%SITE_NAME%;$subsite_name;g"
  fi
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
  php -r '$parts=explode("/", $argv[1]);echo "SITE_NAME=" . $parts[0]."\n"; if (isset($parts[1])) echo "SITE_ID=" . $parts[1] . "\n";' -- "$1"
}

###############################################################################
## Append the civibuild settings directives to a file
## usage: cvutil_inject_settings <php-file> <settings-dir-name> [<preamble>]
## example: cvutil_inject_settings "/var/www/build/drupal/sites/foo/civicrm.settings.php" "civicrm.settings.d"
## example: cvutil_inject_settings "/var/www/build/drupal/sites/foo/settings.php" "drupal.settings.d" 'global $settings;'
function cvutil_inject_settings() {
  local FILE="$1"
  local NAME="$2"
  local PREAMBLE="$3"
  cvutil_assertvars cvutil_inject_settings PRJDIR CIVI_CRED_KEY CIVI_SIGN_KEY SITE_NAME SITE_TYPE SITE_CONFIG_DIR SITE_ID SITE_TOKEN PRIVATE_ROOT FILE NAME
  # Note: CMS_VERSION ought to be defined for use in $civibuild['CMS_VERSION'], but it hasn't always been, and for most build-types its absence would be non-fatal.

  ## Prepare temp file
  local TMPFILE="${TMPDIR}/${SITE_TYPE}/${SITE_NAME}/${SITE_ID}.settings.tmp"
  cvutil_makeparent "$TMPFILE"

  cat > "$TMPFILE" << EOF
<?php
    #### If deployed via civibuild, include any "pre" scripts
    global \$civibuild;
    \$civibuild['PRJDIR'] = '$PRJDIR';
    \$civibuild['SITE_CONFIG_DIR'] = '$SITE_CONFIG_DIR';
    \$civibuild['SITE_TYPE'] = '$SITE_TYPE';
    \$civibuild['SITE_NAME'] = '$SITE_NAME';
    \$civibuild['SITE_ID'] = '$SITE_ID';
    \$civibuild['SITE_TOKEN'] = '$SITE_TOKEN';
    \$civibuild['PRIVATE_ROOT'] = '$PRIVATE_ROOT';
    \$civibuild['WEB_ROOT'] = '$WEB_ROOT';
    \$civibuild['CMS_ROOT'] = '$CMS_ROOT';
    \$civibuild['CMS_VERSION'] = '$CMS_VERSION';
    $PREAMBLE

    if (file_exists(\$civibuild['PRJDIR'].'/src/civibuild.settings.php')) {
      require_once \$civibuild['PRJDIR'].'/src/civibuild.settings.php';
      _civibuild_settings(__FILE__, '$NAME', \$civibuild, 'pre');
    }

EOF

  # Don't know if FILE has good newlines, so prefix/postfix both have extras
  sed 's/^<?php//' < "$FILE" >> "$TMPFILE"

  cat >> "$TMPFILE" << EOF

    #### If deployed via civibuild, include any "post" scripts
    if (file_exists(\$civibuild['PRJDIR'].'/src/civibuild.settings.php')) {
      require_once \$civibuild['PRJDIR'].'/src/civibuild.settings.php';
      _civibuild_settings(__FILE__, '$NAME', \$civibuild, 'post');
    }
EOF

  ## Replace main file with temp file
  cat < "$TMPFILE" > "$FILE"
}

###############################################################################
## usage: cvutil_is_action <string-to-test>
function cvutil_is_action() {
  local action=$1
  ACTION_VALIDATED=0
  for a in $DECLARED_ACTIONS; do
    if [ $a == $action ]; then
      ACTION_VALIDATED=1
    fi
  done
}

###############################################################################
## usage: http_download <url> <local-file>
function http_download() {
  #php -r "echo file_get_contents('$1');" > $2
  if which wget >> /dev/null ; then
    timeout.php $SCM_TIMEOUT wget -O "$2" "$1"
  elif which curl >> /dev/null ; then
    timeout.php $SCM_TIMEOUT curl -L -o "$2" "$1"
  else
    echo "error: failed to locate curl or wget"
  fi
}

## usage: http_cache_setup <url> <local-file> [<ttl-minutes>]
function http_cache_setup() {
  local url="$1"
  local cachefile="$2"
  local lock="${cachefile}.lock"
  local lastrun="${cachefile}.lastrun"
  local ttl=${3:-$CACHE_TTL}

  if [ -f "$cachefile" -a -f "$lastrun" ]; then
    if php -r 'exit($argv[1] + file_get_contents($argv[2]) < time() ? 1 : 0);' -- "$ttl" "$lastrun" ; then
      echo "SKIP: http_cache_setup '$url' $cachefile' (recently updated; ttl=$ttl)"
      return
    fi
  fi

  cvutil_makeparent "$lock"
  if cvutil_php_nodbg pidlockfile.php "$lock" $$ $CACHE_LOCK_WAIT ; then
    php -r 'echo time();' > $lastrun
    if [ ! -f "$cachefile" -o -z "$OFFLINE" ]; then
      echo "[[Update HTTP cache: $url => $cachefile]]"
      cvutil_makeparent "$cachefile"
      http_download "$url" "$cachefile"
    else
      echo "[[Offline mode. Skip cache update: $cachefile]]"
    fi

    rm -f "$lock"
  else
    echo "ERROR: http_cache_setup '$url' '$cachdir': failed to acquire lock"
  fi
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
  local amp_vars_file_path=$(cvutil_php_nodbg mktemp.php ampvar)
  local amp_name="cms$SITE_ID"
  [ "$SITE_ID" == "default" ] && amp_name=cms

  if [ -n "$CMS_URL" ]; then
    cvutil_php_nodbg amp create -f --root="$CMS_ROOT" --name="$amp_name" --prefix=CMS_ --url="$CMS_URL" --output-file="$amp_vars_file_path" --perm="$CMS_DB_PERM"
  else
    cvutil_php_nodbg amp create -f --root="$CMS_ROOT" --name="$amp_name" --prefix=CMS_ --output-file="$amp_vars_file_path" --perm="$CMS_DB_PERM"
  fi

  source "$amp_vars_file_path"
  rm -f "$amp_vars_file_path"
}

function _amp_install_civi() {
  echo "[[Setup MySQL for Civi]]"
  cvutil_assertvars _amp_install_civi CMS_ROOT SITE_NAME SITE_ID TMPDIR
  local amp_vars_file_path=$(cvutil_php_nodbg mktemp.php ampvar)
  local amp_name="civi$SITE_ID"
  [ "$SITE_ID" == "default" ] && amp_name=civi

  cvutil_php_nodbg amp create -f --root="$CMS_ROOT" --name="$amp_name" --prefix=CIVI_ --skip-url --output-file="$amp_vars_file_path" --perm="$CIVI_DB_PERM"

  source "$amp_vars_file_path"
  rm -f "$amp_vars_file_path"
}

function _amp_install_test() {
  echo "[[Setup MySQL for Test]]"
  cvutil_assertvars _amp_install_test CMS_ROOT SITE_NAME SITE_ID TMPDIR
  local amp_vars_file_path=$(cvutil_php_nodbg mktemp.php ampvar)
  local amp_name="test$SITE_ID"
  [ "$SITE_ID" == "default" ] && amp_name=test

  cvutil_php_nodbg amp create -f --root="$CMS_ROOT" --name="$amp_name" --prefix=TEST_ --skip-url --output-file="$amp_vars_file_path" --perm="$TEST_DB_PERM"

  source "$amp_vars_file_path"
  rm -f "$amp_vars_file_path"
}

## Create a headless clone DB
## usage: _amp_install_clone <name> <shell-prefix>
## example: _amp_install_clone cms CLONE_CMS
## example: _amp_install_clone civi CLONE_CIVI
function _amp_install_clone() {
  echo "[[Setup MySQL for \"$2\"]]"
  cvutil_assertvars _amp_install_cms CLONE_DIR SITE_NAME SITE_ID TMPDIR
  local amp_vars_file_path=$(cvutil_php_nodbg mktemp.php ampvar)
  cvutil_php_nodbg amp create -f --root="$CLONE_DIR" --name=$1 --prefix=$2_ --skip-url --output-file="$amp_vars_file_path" --perm="$CIVI_DB_PERM"
  source "$amp_vars_file_path"
  rm -f "$amp_vars_file_path"
}

## Export the description of an amp install and import as shell variables
## usage: _amp_import <root> <name> <shell-prefix>
## example: _amp_imprt /var/www/build/myproject civi CIVI
function _amp_import() {
  cvutil_assertvars _amp_import SITE_NAME SITE_ID TMPDIR
  local amp_vars_file_path=$(cvutil_php_nodbg mktemp.php ampvar)
  cvutil_php_nodbg amp export --root="$1" --name=$2 --prefix=$3_ --output-file="$amp_vars_file_path"
  source "$amp_vars_file_path"
  rm -f "$amp_vars_file_path"
}

###############################################################################
## Backup the databases & http config (using the same structure as amp_install)
function amp_snapshot_create() {
  ## TODO: single-db support

  if [ -z "$CMS_SQL_SKIP" ]; then
    echo "[[Save CMS DB ($CMS_DB_NAME) to file ($CMS_SQL)]]"
    cvutil_assertvars amp_snapshot_create CMS_SQL CMS_DB_ARGS CMS_DB_NAME
    cvutil_makeparent "$CMS_SQL"
    cvutil_php_nodbg amp sql:dump --root="$CMS_ROOT" --passthru="--no-tablespaces" -Ncms | gzip > "$CMS_SQL"
  fi

  if [ -z "$CIVI_SQL_SKIP" ]; then
    echo "[[Save Civi DB ($CIVI_DB_NAME) to file ($CIVI_SQL)]]"
    cvutil_assertvars amp_snapshot_create CIVI_SQL CIVI_DB_ARGS CIVI_DB_NAME
    cvutil_makeparent "$CIVI_SQL"
    cvutil_php_nodbg amp sql:dump --root="$CMS_ROOT" --passthru="--no-tablespaces --routines" -Ncivi | gzip > "$CIVI_SQL"
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
  local orig_CMS_DB_DSN="$CMS_DB_DSN"
  _amp_install_cms
  if [ "$CMS_DB_DSN" != "$orig_CMS_DB_DSN" ]; then
    ## shouldn't happen unless someone has been mucking around...
    echo "WARNING: CMS DB has changed! Config files may be stale!" 1>&2
    echo "  OLD: $orig_CMS_DB_DSN" 1>&2
    echo "  NEW: $CMS_DB_DSN" 1>&2
  fi

  _amp_snapshot_restore "$CMS_ROOT" cms "$CMS_SQL"
}

function _amp_snapshot_restore_civi() {
  local orig_CIVI_DB_DSN="$CIVI_DB_DSN"
  _amp_install_civi
  if [ "$CIVI_DB_DSN" != "$orig_CIVI_DB_DSN" ]; then
    ## shouldn't happen unless someone has been mucking around...
    echo "WARNING: Civi DB has changed! Config files may be stale!" 1>&2
    echo "  OLD: $orig_CIVI_DB_DSN" 1>&2
    echo "  NEW: $CIVI_DB_DSN" 1>&2
  fi

  _amp_snapshot_restore "$CMS_ROOT" civi "$CIVI_SQL"
}

function _amp_snapshot_restore_test() {
  local orig_TEST_DB_DSN="$TEST_DB_DSN"
  _amp_install_test
  if [ "$TEST_DB_DSN" != "$orig_TEST_DB_DSN" ]; then
    ## shouldn't happen unless someone has been mucking around...
    echo "WARNING: TEST DB has changed! Config files may be stale!" 1>&2
    echo "  OLD: $orig_TEST_DB_DSN" 1>&2
    echo "  NEW: $TEST_DB_DSN" 1>&2
  fi

  _amp_snapshot_restore "$CMS_ROOT" test "$CIVI_SQL"
}

## Load a sql snapshot into the given DB
## usage: _amp_snapshot_restore <DB_PREFIX> <sql-file>
## example: _amp_snapshot_restore_clone CMS "/path/to/cms.sql.gz"
## example: _amp_snapshot_restore_clone CIVI "/path/to/civi.sql.gz"
function _amp_snapshot_restore_clone() {
  cvutil_assertvars amp_snapshot_restore_X $1_DB_ARGS $1_DB_NAME
  local db_name=$(eval echo \$${1}_DB_NAME)
  local db_args=$(eval echo \$${1}_DB_ARGS)
  local sql_file="$2"

  echo "[[Restore \"$1\" DB ($db_name) from file ($sql_file)]]"
  if [ ! -f "$sql_file" ]; then
    echo "Missing SQL file: $sql_file" 1>&2
    exit 1
  fi
  gunzip --stdout "$sql_file" | eval mysql $db_args
}

## Load a sql snapshot into the given DB
## usage: _amp_snapshot_restore <amproot> <ampname> <sql-file>
## example: _amp_snapshot_restore "$CMS_ROOT" civi "/path/to/cms.sql.gz"
function _amp_snapshot_restore() {
  cvutil_assertvars amp_snapshot_restore_X $1_DB_ARGS $1_DB_NAME
  local db_root="$1"
  local db_name="$2"
  local sql_file="$3"

  echo "[[Restore \"$1\" DB ($db_name) from file ($sql_file)]]"
  if [ ! -f "$sql_file" ]; then
    echo "Missing SQL file: $sql_file" 1>&2
    exit 1
  fi
  gunzip --stdout "$sql_file" | cvutil_php_nodbg amp sql --root="$db_root" --name="$db_name"
}


###############################################################################
## Tear down HTTP and MySQL services
function amp_uninstall() {
  echo "WARNING: amp_uninstall: Retaining DB & site config to provide continuity among rebuilds"
}

###############################################################################
## Download APIv4, if it's not built into the target version of Civi
## usage: api4_download_conditional <civicrm-path> <api4-path>
function api4_download_conditional() {
  cvutil_assertvars api4_download_conditional CIVI_VERSION CACHE_DIR
  local civi_path="$1"
  local api4_path="$2"

  if [ -z "$api4_path" -o -z "$civi_path" ]; then
    cvutil_fatal "Cannot download api4: Target path not specified"
  fi

  if [ ! -e "$civi_path" ]; then
    cvutil_fatal "Cannot download api4: Must download civicrm-core first"
  fi

  if [ -e "$civi_path/Civi/Api4" ]; then
    ## Circa 5.19.alpha, api4 is merged into core.
    echo "Found api4 in core: "$civi_path/Civi/Api4""
    return;
  fi

  case "$CIVI_VERSION" in
    ## Circa v5.16 (3e20c1acb397d6dfe?), api4+core got into a bidrectional dependency, and api4@~4.5
    ## seems to be the closest release that corresponds to the dev-periods of 5.16-5.18.
    ## Circa v5.19.alpha1 (#15309), api4 should be merged into core.
    master|5.16*|5.17*|5.18*|5.19*) git_cache_setup_id civicrm/api4 ; git clone "${CACHE_DIR}/civicrm/api4.git" -b "4.5" "$api4_path" ;;
    # 5.14*|5.15*) git clone "${CACHE_DIR}/civicrm/api4.git" -b "4.4" "$api4_path" ;;
    *) echo "Skipping api4 download" ;; ## Shrug
      ##EXTCIVIVER=$( php -r '$x=simplexml_load_file("civicrm/xml/version.xml"); echo $x->version_no;' )
      ##cv dl -b "@https://civicrm.org/extdir/ver=$EXTCIVIVER|cms=Drupal|status=|ready=/org.civicrm.api4.xml" --to="$WEB_ROOT/web/sites/all/modules/civicrm/ext/api4" --dev
  esac
}

## Allow common composer plugins
function composer_allow_common_plugins() {
  local PLG
  for PLG in  "composer/installers"  "drupal/core-composer-scaffold" "drupal/core-project-message" "cweagans/composer-patches" "civicrm/civicrm-asset-plugin" "civicrm/composer-downloads-plugin" "civicrm/composer-compile-plugin" ; do
    composer config --no-interaction allow-plugins."$PLG" true
  done
}

###############################################################################
## Download CiviCRM (via composer, into an existing D8/composer project)
##
## This function shouldn't be necessary in the long-term; but for testing
## right now across different versions, we need some hackery/backporting,
## and this allows one to avoid copy-pasting those fiddly bits.
##
## Be sure to "cd" into the root of the composer project, then call `civicrm_download_composer_d8`
function civicrm_download_composer_d8() {
  cvutil_assertvars civicrm_download_composer_d8 CIVI_VERSION CMS_VERSION

  composer config 'extra.enable-patching' true
  ## Ensure that we compile all our js as necessary
  composer config extra.compile-mode all
  composer config minimum-stability dev

  local CIVI_VERSION_COMP=$(civicrm_composer_ver "$CIVI_VERSION")
  local EXTRA_COMPOSER=()
  local EXTRA_PATCH=()

  case "$CIVI_VERSION" in
    5.21*) EXTRA_COMPOSER+=( 'civicrm/civicrm-asset-plugin:~1.1' ) ; EXTRA_COMPOSER+=( "civicrm/civicrm-setup:0.4.0 as 0.2.99" ) ; EXTRA_COMPOSER+=( 'cache/integration-tests:dev-master#b97328797ab199f0ac933e39842a86ab732f21f9' ) ; EXTRA_PATCH+=( "https://github.com/civicrm/civicrm-core/pull/16328" ); ;;
    5.22*) EXTRA_COMPOSER+=( 'civicrm/civicrm-asset-plugin:~1.1' ) ; EXTRA_COMPOSER+=( "civicrm/civicrm-setup:0.4.0 as 0.2.99" ) ; EXTRA_COMPOSER+=( 'cache/integration-tests:dev-master#b97328797ab199f0ac933e39842a86ab732f21f9' ) ; EXTRA_PATCH+=( "https://github.com/civicrm/civicrm-core/pull/16413" ); ;;
    5.23*) EXTRA_COMPOSER+=( 'civicrm/civicrm-asset-plugin:~1.1' ) ; EXTRA_COMPOSER+=( 'cache/integration-tests:dev-master#b97328797ab199f0ac933e39842a86ab732f21f9' ); ;;
    5.24*) EXTRA_COMPOSER+=( 'civicrm/civicrm-asset-plugin:~1.1' ) ; ;;
    5.25*) EXTRA_COMPOSER+=( 'civicrm/civicrm-asset-plugin:~1.1' ) ; ;;
    5.26*) EXTRA_COMPOSER+=( 'civicrm/civicrm-asset-plugin:~1.1' ) ; ;;
    5.27*) EXTRA_COMPOSER+=( 'civicrm/civicrm-asset-plugin:~1.1' ) ; ;;
    5.28*) EXTRA_COMPOSER+=( 'civicrm/civicrm-asset-plugin:~1.1' ) ; ;;
    5.29*) EXTRA_COMPOSER+=( 'civicrm/civicrm-asset-plugin:~1.1' ) ; ;;
    5.30*) EXTRA_COMPOSER+=( 'civicrm/civicrm-asset-plugin:~1.1' ) ; ;;
    *) echo "No extra patches required" ; ;;
  esac

  ## Older D8 version had weird conflict involving pear/pear_exception and drupal-composer/drupal-project
  case "$CMS_VERSION" in
    8.9*) echo 'No Extra Patch required' ; ;;
    8*) EXTRA_COMPOSER+=( 'pear/pear_exception:1.0.1 as 1.0.0') ; ;; ## weird conflict in drupal-composer/drupal-project
    *) echo 'No Extra Patch required' ; ;;
  esac

  composer require "${EXTRA_COMPOSER[@]}" civicrm/civicrm-{core,packages,drupal-8}:"$CIVI_VERSION_COMP" --prefer-source
  [ -n "$EXTRA_PATCH" ] && git scan am -N "${EXTRA_PATCH[@]}"

  local civicrm_version_php=$(find -name civicrm-version.php)
  if [ -f "$civicrm_version_php" ]; then
    local civi_root=$(dirname "$civicrm_version_php")
    #extract-url --cache-ttl 172800 vendor/civicrm/civicrm-core=http://download.civicrm.org/civicrm-l10n-core/archives/civicrm-l10n-daily.tar.gz ## Issue: Don't write directly into vendor tree
    extract-url --cache-ttl 172800 "$civi_root=http://download.civicrm.org/civicrm-l10n-core/archives/civicrm-l10n-daily.tar.gz" ## Issue: Don't write directly into vendor tree
  else
    cvutil_fatal "Cannot download l10n data - failed to locate civicrm-core"
  fi
}

###############################################################################
## Generate config files and setup database
function civicrm_install() {
  cvutil_assertvars civicrm_install CIVI_CORE CIVI_FILES CIVI_TEMPLATEC

  if [ ! -d "$CIVI_CORE/bin" -o ! -d "$CIVI_CORE/CRM" ]; then
    cvutil_fatal "Failed to locate valid civi root: $CIVI_CORE"
  fi

  ## Create CiviCRM data dirs
  cvutil_php_nodbg amp datadir "$CIVI_FILES" "$CIVI_TEMPLATEC"
  if [ -n "$CIVI_EXT_DIR" ]; then
    cvutil_php_nodbg amp datadir "$CIVI_EXT_DIR"
  fi

  ## Create CiviCRM config files
  civicrm_make_settings_php
  civicrm_make_setup_conf
  civicrm_make_test_settings_php

  pushd "$CIVI_CORE" >> /dev/null
    ## Does this build include development support (eg git or tarball-based)?
    if [ -e "xml" -a -e "bin/setup.sh" -a -n "$NO_SAMPLE_DATA" ]; then
      env SITE_ID="$SITE_ID" bash ./bin/setup.sh -Dgsdf
    elif [ -e "xml" -a -e "bin/setup.sh" -a -z "$NO_SAMPLE_DATA" ]; then
      env SITE_ID="$SITE_ID" bash ./bin/setup.sh
    elif [ -e "sql/civicrm.mysql" -a -e "sql/civicrm_generated.mysql" -a -z "$NO_SAMPLE_DATA" ]; then
      cat sql/civicrm.mysql sql/civicrm_generated.mysql | cvutil_php_nodbg amp sql -Ncivi --root="$CMS_ROOT"
    elif [ -e "sql/civicrm.mysql" -a -e "sql/civicrm_data.mysql" -a -n "$NO_SAMPLE_DATA" ]; then
      cat sql/civicrm.mysql sql/civicrm_data.mysql | cvutil_php_nodbg amp sql -Ncivi --root="$CMS_ROOT"
    else
      echo "Failed to locate civi SQL files"
    fi
  popd >> /dev/null

  civicrm_update_domain
}

###############################################################################
## Generate config files and setup database. (Use either newer or older installer, depending on version).
function civicrm_install_transitional() {
  cvutil_assertvars civicrm_install CIVI_CORE

  ## If installing an older version, provide continuity (for purposes of test matrices/contrib tests/etc).
  if civicrm_check_ver '<' 5.57.alpha1 ; then

    civicrm_install

  ## Newer versions should use 'cv core:install' to match regular web-installer
  else
    # If you've switched branches and triggered `reinstall`, then you need to refresh composer deps/autoloader before installing
    (cd "$CIVI_CORE" && composer install)

    civicrm_install_cv

    ## Generating `civicrm.config.php` is necessary for `extern/*.php` and its E2E tests
    (cd "$CIVI_CORE" && ./bin/setup.sh -g)
  fi
}

###############################################################################
## Generate config files and setup database (via cv)
function civicrm_install_cv() {
  cvutil_assertvars civicrm_install CIVI_CORE CIVI_DB_DSN CMS_URL CIVI_SITE_KEY

  if [ ! -d "$CIVI_CORE/bin" -o ! -d "$CIVI_CORE/CRM" ]; then
    cvutil_fatal "Failed to locate valid civi root: $CIVI_CORE"
  fi

  local loadGenOpt
  [ -n "$NO_SAMPLE_DATA" ] && loadGenOpt="" || loadGenOpt="-m loadGenerated=1"
  declare -a installOpts=()
  if [ "$CIVI_UF" == "Standalone" ]; then
    cvutil_assertvars civicrm_install ADMIN_USER ADMIN_PASS ADMIN_EMAIL
    installOpts+=("-m" "extras.adminUser=$ADMIN_USER" "-m" "extras.adminPass=$ADMIN_PASS" -m "extras.adminEmail=$ADMIN_EMAIL")
  fi
  if [ -z "$NO_SAMPLE_DATA" ]; then
    installOpts+=("-m" "loadGenerated=1")
  fi
  if [ -n "$CIVI_EXT_DIR" ]; then
    installOpts+=("-m" "settings.extensionsDir=$CIVI_EXT_DIR")
    installOpts+=("-m" "settings.extensionsURL=$CIVI_EXT_URL")
  fi
  cv core:install -vv -f --cms-base-url="$CMS_URL" --db="$CIVI_DB_DSN" -m "siteKey=$CIVI_SITE_KEY" "${installOpts[@]}"
  local settings=$( cv ev 'echo CIVICRM_SETTINGS_PATH;' )
  cvutil_inject_settings "$settings" "civicrm.settings.d"
  civicrm_update_domain

  ## Enable development
  civicrm_make_setup_conf
  civicrm_make_test_settings_php
}

###############################################################################
## Update the CiviCRM domain's name+email
function civicrm_update_domain() {
  cvutil_assertvars civicrm_install CIVI_DOMAIN_NAME CIVI_DOMAIN_EMAIL
  cvutil_php_nodbg amp sql -Ncivi --root="$CMS_ROOT" <<EOSQL
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
## Get a list of default permissions for anonymous users
function civicrm_apply_d8_perm_defaults() {
  ## FIXME: The lists need a better home.
  drush8 -y role-create demoadmin
  drush8 -y role-add-perm anonymous "access CiviMail subscribe/unsubscribe pages,access all custom data,access uploaded files,make online contributions,profile create,profile view,register for events"
  drush8 -y role-add-perm demoadmin "access AJAX API,access all custom data,access CiviContribute,access CiviCRM,access CiviEvent,access CiviMail,access CiviMail subscribe/unsubscribe pages,access CiviMember,access CiviReport,access Contact Dashboard,access contact reference fields,access deleted contacts,access Report Criteria,save Report Criteria,access uploaded files,add contacts,administer CiviCRM,administer dedupe rules,administer Reports,administer reserved groups,administer reserved reports,administer reserved tags,administer Tagsets,delete activities,delete contacts,delete in CiviContribute,delete in CiviEvent,delete in CiviMail,delete in CiviMember,edit all contacts,view my contact,edit my contact,edit all events,edit contributions,edit event participants,edit message templates,edit groups,edit memberships,import contacts,make online contributions,manage tags,merge duplicate contacts,profile create,profile edit,profile listings,profile listings and forms,profile view,register for events,translate CiviCRM,view all activities,view all contacts,view all notes,view event info,view event participants,view public CiviMail content,administer payment processors,create manual batch,edit own manual batches,edit all manual batches,view own manual batches,view all manual batches,delete own manual batches,delete all manual batches,export own manual batches,export all manual batches"
  drush8 -y role-add-perm demoadmin "access toolbar"
}

###############################################################################
## Appy more default values
function civicrm_apply_demo_defaults() {
  if cv ev 'exit(version_compare(CRM_Utils_System::version(), "4.7.0", "<") ?0:1);' ; then
    cv api setting.create versionCheck=0 debug=1
  fi
  cv api MailSettings.create id=1 is_default=1 domain=example.org debug=1
  cv en --ignore-missing 'civigrant'
  if [ -z "$NO_SAMPLE_DATA" ]; then
    cv -v ev 'eval(file_get_contents("php://stdin"));' <<EOPHP
      \$cid = civicrm_api3('Domain', 'getvalue', array(
        'id' => 1,
        'return' => 'contact_id'
      ));
      civicrm_api3('Address', 'create', array(
        'contact_id' => \$cid,
        'location_type_id' => 1,
        'street_address' => '123 Some St',
        'city' => 'Hereville',
        'country_id' => 'US',
        'state_province_id' => 'California',
        'postal_code' => '94100',
        'options' => array(
          'match' => array('contact_id', 'location_type_id'),
        ),
      ));
EOPHP
  fi
  if cv ev 'exit(version_compare(CRM_Utils_System::version(), "5.19.alpha", "<") ?0:1);' ; then
    cv en --ignore-missing api4
  fi
  cv en --ignore-missing $CIVI_DEMO_EXTS
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
  TEST_DB_HOSTPORT=$(cvutil_build_hostport "$TEST_DB_HOST" "$TEST_DB_PORT")
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
    | sed "s;%%testHost%%;${TEST_DB_HOSTPORT};" \
    | sed "s;%%testName%%;${TEST_DB_NAME};" \
    | sed "s;%%testPass%%;${TEST_DB_PASS};" \
    | sed "s;%%testUser%%;${TEST_DB_USER};" \
    | sed "s;%%siteKey%%;${CIVI_SITE_KEY};" \
    | sed "s;%%credKeys%%;aes-cbc::${CIVI_CRED_KEY};" \
    | sed "s;%%signKeys%%;jwt-hs256::${CIVI_SIGN_KEY};" \
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

  cvutil_inject_settings "$CIVI_SETTINGS" "civicrm.settings.d"
}

###############################################################################
## Generate a "setup.conf" file
function civicrm_make_setup_conf() {
  cvutil_assertvars civicrm_make_setup_conf PRJDIR CMS_ROOT CIVI_CORE CIVI_UF CIVI_DB_NAME CIVI_DB_USER CIVI_DB_PASS

  cat > "$CIVI_CORE/bin/setup.conf" << EOF
    ## INFRA-114
    PRJDIR="$PRJDIR"
    CMS_ROOT="$CMS_ROOT"
    SITE_ID="\${SITE_ID:-$SITE_ID}"
    AMP_NAME=civi\${SITE_ID}
    [ "\$SITE_ID" == "default" ] && AMP_NAME=civi
    eval \`\$PRJDIR/bin/amp export --root="\$CMS_ROOT" -N\${AMP_NAME}\`
    DBNAME="\$AMP_DB_NAME"
    DBUSER="\$AMP_DB_USER"
    DBPASS="\$AMP_DB_PASS"
    DBHOST="\$AMP_DB_HOST"
    DBPORT="\$AMP_DB_PORT"
    ##
    SVNROOT="$CIVI_CORE"
    CIVISOURCEDIR="$CIVI_CORE"
    SCHEMA=schema/Schema.xml
    DBARGS=""
    PHP5PATH=
    DBLOAD="$DBLOAD"
    # DBADD=
    GENCODE_CMS="$CIVI_UF"
EOF

  if [ -n "$GENCODE_CONFIG_TEMPLATE" ]; then
    echo "GENCODE_CONFIG_TEMPLATE=\"$GENCODE_CONFIG_TEMPLATE\"" >> "$CIVI_CORE/bin/setup.conf"
    echo "export GENCODE_CONFIG_TEMPLATE" >> "$CIVI_CORE/bin/setup.conf"
  fi
}

###############################################################################
## Generate civicrm.settings.php and CiviSeleniumSettings.php for testing
function civicrm_make_test_settings_php() {
  cvutil_assertvars civicrm_make_test_settings_php CIVI_CORE CIVI_DB_NAME CIVI_DB_USER CIVI_DB_PASS CIVI_DB_HOST CMS_URL CMS_DB_USER CMS_DB_PASS CMS_DB_HOST CMS_DB_NAME ADMIN_USER ADMIN_PASS DEMO_USER DEMO_PASS CIVI_SITE_KEY

  ## Does this build include development support (eg git or tarball-based)?
  if [ -d "$CIVI_CORE/tests/phpunit/CiviTest" ]; then
    ## TODO: REVIEW
    cat > "$CIVI_CORE/tests/phpunit/CiviTest/civicrm.settings.local.php" << EOF
<?php
  if (!defined('CIVICRM_DSN')) {
    if (defined('CIVICRM_WEBTEST')) {
      // For Selenium tests, use normal DB
      define('CIVICRM_DSN', "mysql://${CIVI_DB_USER}:${CIVI_DB_PASS}@${CIVI_DB_HOST}:${CIVI_DB_PORT}/${CIVI_DB_NAME}");
      define('CIVICRM_UF_DSN', "mysql://${CMS_DB_USER}:${CMS_DB_PASS}@${CMS_DB_HOST}:${CMS_DB_PORT}/${CMS_DB_NAME}");
    } else {
      // For unit tests, use headless test DB
      define('CIVICRM_DSN', "mysql://${TEST_DB_USER}:${TEST_DB_PASS}@${TEST_DB_HOST}:${TEST_DB_PORT}/${TEST_DB_NAME}");
    }
  }
  if (!defined('CIVICRM_TEMPLATE_COMPILEDIR')) {
    define('CIVICRM_TEMPLATE_COMPILEDIR', '${CIVI_TEMPLATEC}');
  }
  if (!defined('DONT_DOCUMENT_TEST_CONFIG')) {
    define('DONT_DOCUMENT_TEST_CONFIG', TRUE);
  }
EOF

    cvutil_inject_settings "$CIVI_CORE/tests/phpunit/CiviTest/civicrm.settings.local.php" "civitest.settings.d"

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
  var \$cookies;

  function __construct() {
    \$this->fullSandboxPath = \$this->sandboxURL . \$this->sandboxPATH;
    \$this->cookies = array(
      \$this->createConstCookie(),
    );
  }

  /**
   * @return array
   */
  function createConstCookie() {
    global \$civibuild;
    \$now = time();
    \$civiConsts = array(
      'CIVICRM_DSN' => CIVICRM_DSN,
      'CIVICRM_UF_DSN' => CIVICRM_UF_DSN,
      'ts' => \$now,
      'sig' => md5(implode(';;', array(CIVICRM_DSN, CIVICRM_UF_DSN, \$civibuild['SITE_TOKEN'], \$now))),
    );

    return array(
      'name' => 'civiConsts',
      'value' => urlencode(json_encode(\$civiConsts)),
    );
  }
}
EOF
  fi
}

###############################################################################
## Determine the version# of the CiviCRM codebase
## usage: civicrm_get_ver <path>
## ex:    ver=$(civicrm_get_ver .)
## ex:    ver=$(civicrm_get_ver /var/www/sites/all/modules/civicrm)
function civicrm_get_ver() {
  pushd "$1" >> /dev/null
    if [ -f xml/version.xml ]; then
      ## Works in any git-based build, even if gencode hasn't run yet.
      php -r 'echo simplexml_load_file("xml/version.xml")->version_no;'
    else
      ## works in any tar-based build.
      php -r 'require "civicrm-version.php"; $a = civicrmVersion(); echo $a["version"];'
    fi
  popd >> /dev/null
}

###############################################################################
## Check if the civicrm matches some condition
## usage: civicrm_check_ver <op> <target>
## example: if civicrm_check_ver '>=' '5.43' ; then echo NEW; else echo OLD; fi
function civicrm_check_ver() {
  cvutil_assertvars civicrm_check_ver CIVI_CORE
  local ver=$( civicrm_get_ver "$CIVI_CORE" )
  if env ACTUAL="$ver" OP="$1" EXPECT="$2" php -r 'exit(version_compare(getenv("ACTUAL"), getenv("EXPECT"), getenv("OP"))?0:1);'; then
    return 0
  else
    return 1
  fi
}

###############################################################################
## usage: civicrm_ext_download_bare <key> <path>
function civicrm_ext_download_bare() {
  local civiVer=$(civicrm_get_ver .)
  cv dl -b "@https://civicrm.org/extdir/ver=$civiVer|cms=Drupal/$1.xml" --to="$2"
}

###############################################################################
## usage: Convert a CiviCRM version branch/tag expression to a composer version expression
## example: civicrm_composer_ver master ==> "dev-master"
function civicrm_composer_ver() {
  local branchTag="$1"
  if [[ "$branchTag" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    ## Specific tag versions don't need to be changed.
    echo "$branchTag"
  elif [[ "$branchTag" =~ ^[0-9]+\.[0-9]+$ ]]; then
    ## Numeric branches get a dev suffix
    echo "$branchTag.x-dev"
  elif [[ "$branchTag" =~ dev ]]; then
    ## "dev-" indicates that the caller has already put into composer notation.
    echo "$branchTag"
  else
    ## Non-numeric branches get a dev prefix
    echo "dev-$branchTag"
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
        define('WP_AUTO_UPDATE_CORE', 'minor');
PHP

    wp core install \
      --url="$CMS_URL" \
      --admin_user="$ADMIN_USER" \
      --admin_password="$ADMIN_PASS" \
      --admin_email="$ADMIN_EMAIL" \
      --title="$CMS_TITLE"

    ## Create WP data dirs
    cvutil_mkdir "wp-content/plugins/modules"
    cvutil_php_nodbg amp datadir "wp-content/plugins/files" "wp-content/uploads/"

    cvutil_inject_settings "wp-config.php" "wp-config.d"
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
## Backdrop -- Generate config files and setup database
## usage: backdrop_install <extra-drush-args>
## To use an "install profile", simply pass it as part of <extra-drush-args>
function backdrop_install() {
  cvutil_assertvars backdrop_install CMS_ROOT SITE_ID CMS_TITLE CMS_DB_USER CMS_DB_PASS CMS_DB_HOST CMS_DB_NAME ADMIN_USER ADMIN_PASS CMS_URL
  pushd "$CMS_ROOT" >> /dev/null
    cvutil_php_nodbg amp datadir "files" "${PRIVATE_ROOT}/"

    CMS_DB_HOSTPORT=$(cvutil_build_hostport "$CMS_DB_HOST" "$CMS_DB_PORT")
    ./core/scripts/install.sh "$@" \
      --db-url="mysql://${CMS_DB_USER}:${CMS_DB_PASS}@${CMS_DB_HOSTPORT}/${CMS_DB_NAME}" \
      --account-name="$ADMIN_USER" \
      --account-pass="$ADMIN_PASS" \
      --account-mail="$ADMIN_EMAIL" \
      --site-name "$CMS_TITLE"

    cvutil_inject_settings "$CMS_ROOT/settings.php" "backdrop.settings.d"

    ## FIXME: no drush for backdrop: drush vset --yes file_private_path "${PRIVATE_ROOT}/${DRUPAL_SITE_DIR}"
    [ -n "$APACHE_VHOST_ALIAS" ] && cvutil_ed .htaccess '# RewriteBase /$' 's;# RewriteBase /$;RewriteBase /;'
  popd >> /dev/null
}

###############################################################################
## Backdrop -- Destroy config files and database tables
function backdrop_uninstall() {
  cvutil_assertvars backdrop_uninstall CMS_ROOT SITE_ID CMS_URL

  pushd "$CMS_ROOT" >> /dev/null
    git checkout -- settings.php
    rm -rf files
    git checkout -- files/
  popd >> /dev/null

  if [ -n "$DRUPAL_SITE_DIR" -a -d "$PRIVATE_ROOT/$DRUPAL_SITE_DIR" ]; then
    rm -rf "$PRIVATE_ROOT/$DRUPAL_SITE_DIR"
  fi
}

###############################################################################
## Backdrop - Create a user
## usage: backdrop_user USERNAME EMAIL PASSWORD
function backdrop_user() {
  env NEW_USER="$1" NEW_EMAIL="$2" NEW_PASS="$3" \
    cv ev --level=cms-only --user=admin '$ps=["name"=>getenv("NEW_USER"), "mail"=>getenv("NEW_EMAIL"), "pass"=>getenv("NEW_PASS")]; $u=entity_create("user", $ps); $u->save();'
}

###############################################################################
## Add a role to a user
## usage: backdrop_user_role USERNAME ROLENAME
function backdrop_user_role() {
  echo 'INSERT IGNORE INTO users_roles (uid,role) SELECT uid, @ENV[THE_ROLE] FROM users WHERE name = @ENV[THE_USER];' \
    | env THE_USER="$1" THE_ROLE="$2" amp sql -Ncms -e
}

###############################################################################
## Backdrop - Download to WEB_ROOT/web. Apply core patches (eg for MySQL 8) as required.
function backdrop_download() {
  cvutil_assertvars backdrop_download WEB_ROOT CMS_VERSION PRJDIR CACHE_DIR
  echo "[[Download Backdrop]]"
  mkdir "$WEB_ROOT"
  git_cache_clone backdrop/backdrop "$WEB_ROOT/web" -b "$CMS_VERSION"

  # See: https://github.com/backdrop/backdrop/pull/3018
  pushd "$WEB_ROOT/web/core/includes/database/mysql"
    if grep -q 'NO_AUTO_CREATE_USER' database.inc; then
      patch database.inc < "$PRJDIR/app/drupal-patches/mysql8-drupal.patch"
    fi
  popd
}

###############################################################################
## Drupal - Download to WEB_ROOT/web. Apply core patches (eg for MySQL 8) as required.
function drupal_download() {
  cvutil_assertvars drupal_download WEB_ROOT CMS_VERSION PRJDIR
  mkdir "$WEB_ROOT"
  drush8 -y dl drupal-${CMS_VERSION} --destination="$WEB_ROOT" --drupal-project-rename
  mv "$WEB_ROOT/drupal" "$WEB_ROOT/web"

  case $CMS_VERSION in
    7*)
     # See: https://www.drupal.org/project/drupal/issues/2978575
     pushd "$WEB_ROOT/web/includes/database/mysql"
       if ! grep -q 'escapeAlias' database.inc; then
         patch database.inc < "$PRJDIR/app/drupal-patches/mysql8-drupal.patch"
       fi
     popd
  esac
}

###############################################################################
## Drupal -- Generate config files and setup database
## currently just a wrapper for drupal7 install - but may add crazy logic ... like an if.
## usage: drupal_install <extra-drush-args>
## To use an "install profile", simply pass it as part of <extra-drush-args>
function drupal_install() {
  drupal7_install
}
###############################################################################
## Drupal -- Generate config files and setup database
## usage: drupal_install <extra-drush-args>
## To use an "install profile", simply pass it as part of <extra-drush-args>
function drupal7_install() {
  cvutil_assertvars drupal7_install CMS_ROOT SITE_ID CMS_TITLE CMS_DB_USER CMS_DB_PASS CMS_DB_HOST CMS_DB_NAME ADMIN_USER ADMIN_PASS CMS_URL
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
    cvutil_inject_settings "$CMS_ROOT/sites/$DRUPAL_SITE_DIR/settings.php" "drupal.settings.d"
    chmod u-w "sites/$DRUPAL_SITE_DIR/settings.php"

    ## Setup extra directories
    cvutil_php_nodbg amp datadir "sites/${DRUPAL_SITE_DIR}/files" "${PRIVATE_ROOT}/${DRUPAL_SITE_DIR}"
    cvutil_mkdir "sites/${DRUPAL_SITE_DIR}/modules"
    drush vset --yes file_private_path "${PRIVATE_ROOT}/${DRUPAL_SITE_DIR}"
    [ -n "$APACHE_VHOST_ALIAS" ] && cvutil_ed .htaccess '# RewriteBase /$' 's;# RewriteBase /$;RewriteBase /;'
  popd >> /dev/null
}

###############################################################################
## Drupal -- Generate config files and setup database
## usage: drupal_install <extra-drush-args>
## To use an "install profile", simply pass it as part of <extra-drush-args>
function drupal8_install() {
  cvutil_assertvars drupal8_install CMS_ROOT SITE_ID CMS_TITLE CMS_DB_USER CMS_DB_PASS CMS_DB_HOST CMS_DB_NAME ADMIN_USER ADMIN_PASS CMS_URL
  DRUPAL_SITE_DIR=$(_drupal_multisite_dir "$CMS_URL" "$SITE_ID")
  CMS_DB_HOSTPORT=$(cvutil_build_hostport "$CMS_DB_HOST" "$CMS_DB_PORT")
  pushd "$CMS_ROOT" >> /dev/null
    [ -d "sites/$DRUPAL_SITE_DIR" ] && chmod u+w "sites/$DRUPAL_SITE_DIR"
    [ -f "sites/$DRUPAL_SITE_DIR/settings.php" ] && chmod u+w "sites/$DRUPAL_SITE_DIR/settings.php" && rm -f "sites/$DRUPAL_SITE_DIR/settings.php"

    drush8 site-install -y "$@" \
      --db-url="mysql://${CMS_DB_USER}:${CMS_DB_PASS}@${CMS_DB_HOSTPORT}/${CMS_DB_NAME}" \
      --account-name="$ADMIN_USER" \
      --account-pass="$ADMIN_PASS" \
      --account-mail="$ADMIN_EMAIL" \
      --site-name="$CMS_TITLE" \
      --sites-subdir="$DRUPAL_SITE_DIR"
    chmod u+w "sites/$DRUPAL_SITE_DIR"
    chmod u+w "sites/$DRUPAL_SITE_DIR/settings.php"
    cvutil_inject_settings "$CMS_ROOT/sites/$DRUPAL_SITE_DIR/settings.php" "drupal.settings.d" "global \$settings; \$civibuild['DRUPAL_SITE_DIR'] = '$DRUPAL_SITE_DIR';"
    chmod u-w "sites/$DRUPAL_SITE_DIR/settings.php"

    ## Setup extra directories
    cvutil_php_nodbg amp datadir "sites/${DRUPAL_SITE_DIR}/files" "${PRIVATE_ROOT}/${DRUPAL_SITE_DIR}"
    cvutil_mkdir "sites/${DRUPAL_SITE_DIR}/modules"
    [ -n "$APACHE_VHOST_ALIAS" ] && cvutil_ed .htaccess '# RewriteBase /$' 's;# RewriteBase /$;RewriteBase /;'
  popd >> /dev/null
}

###############################################################################
## Drupal -- Destroy config files and database tables
function drupal_uninstall() {
  drupal7_uninstall
}

###############################################################################
## Drupal -- Destroy config files and database tables
function drupal7_uninstall() {
  cvutil_assertvars drupal7_uninstall CMS_ROOT SITE_ID CMS_URL
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
## Drupal -- Destroy config files and database tables
function drupal8_uninstall() {
  cvutil_assertvars drupal8_uninstall CMS_ROOT SITE_ID CMS_URL
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
## Drupal 7 - Download PO files for drupal modules.
##
## This is similar to "l10n_update", but it doesn't require an active D7 site or database,
## so it works well with 'download' phase and with a shared cache.
##
## Usage: drupal7_po_download <language-list> <translation-projects...>
## Example: drupal7_po_download de_DE,fr_FR,nl_NL drupal-7.x views-7.x-3.x
function drupal7_po_download() {
  cvutil_assertvars drupal7_po_download WEB_ROOT
  local SPOOL="${WEB_ROOT}/web/sites/all/translations"
  _drupalx_po_download "$SPOOL" "$@"
}

###############################################################################
## Drupal 7 - Load PO files into database
##
## Find any "*.po" files in D7 (sites/all/translations/*.po). Activate the associated languages and import the strings.
##
## Usage: drupal7_po_import
function drupal7_po_import() {
  cvutil_assertvars drupal7_po_import WEB_ROOT
  local SPOOL="${WEB_ROOT}/web/sites/all/translations"
  _drupalx_po_import "$SPOOL" "$@"
}

###############################################################################
## Drupal 8 - Download PO files for drupal modules.
##
## Usage: drupal8_po_download <language-list> <translation-projects...>
## Example: drupal8_po_download de_DE,fr_FR,nl_NL drupal-8.x
function drupal8_po_download() {
  cvutil_assertvars drupal8_po_download WEB_ROOT
  local SPOOL="${WEB_ROOT}/share/translations"
  _drupalx_po_download "$SPOOL" "$@"
}

###############################################################################
## Drupal 8 - Load PO files into database
##
## Find any "*.po" files in D8 (l10n/*.po). Activate the associated languages and import the strings.
##
## Usage: drupal8_po_import
function drupal8_po_import() {
  cvutil_assertvars drupal8_po_import WEB_ROOT
  local SPOOL="${WEB_ROOT}/share/translations"
  if [[ ! -d "$SPOOL" ]]; then
    mkdir -p "$SPOOL"
  fi
  echo "FIXME: The function drupal8_po_import() should be updated to handle imports on Drupal 8+" > "$SPOOL/FIXME.txt"
  echo "WARNING: Skipped drupal8_po_import(). Not yet supported on Backdrop." 1>&2
  # Issue: At time of writing, our copy of drush-language doesn't seem to work on Drupal 9.
  #_drupalx_po_import "$SPOOL" "$@"
}

###############################################################################
## Backdrop - Download PO files for Backdrop modules.
##
## Usage: backdrop_po_download <language-list> <translation-projects...>
## Example: backdrop_po_download de_DE,fr_FR,nl_NL backdropcms-1.23
function backdrop_po_download() {
  cvutil_assertvars backdrop_po_download WEB_ROOT
  #local SPOOL="${WEB_ROOT}/web/files/translations"  ## Suggested by some BD docs, but it doesn't seem to be required, and it's extraneously wiped on reinstalls.
  local SPOOL="${WEB_ROOT}/web/sites/all/translations"
  _drupalx_po_download "$SPOOL" "$@"
}

###############################################################################
## Backdrop - Load PO files into database
##
## Usage: backdrop_po_import
function backdrop_po_import() {
  cvutil_assertvars backdrop_po_download WEB_ROOT
  #local SPOOL="${WEB_ROOT}/web/files/translations"  ## Suggested by some BD docs, but it doesn't seem to be required, and it's extraneously wiped on reinstalls.
  local SPOOL="${WEB_ROOT}/web/sites/all/translations"
  echo "FIXME: The function backdrop_po_import() should be updated to handle imports on Backdrop" > "$SPOOL/FIXME.txt"
  echo "WARNING: Skipped backdrop_po_import(). Not yet supported on Backdrop." 1>&2
  # Issue: At time of writing, our copy of drush-language doesn't seem to work on Backdrop.
  #_drupalx_po_import "$SPOOL" "$@"
}

###############################################################################
## D7/BD - Download PO files
##
## Usage: _drupalx_po_download <spool-dir> <language-list> <translation-projects...>
## Example: _drupalx_po_download "$WEB_ROOT/translations" "de_DE,fr_FR,nl_NL" drupal-7.x views-7.x-3.x
function _drupalx_po_download() {
  local SPOOL="$1"
  shift
  local CSV="$1"
  local TTL=86400
  shift
  local NEW_LOCALES=$( echo "$CSV" | awk 'BEGIN {RS=","; FS="_"} {print $1}' | sort -u | grep -v ^en )
  if [ -z "$NEW_LOCALES" ]; then
    return
  fi

  mkdir -p "${SPOOL}"

  for NEW_LOCALE in $NEW_LOCALES; do
    for TARGET in "$@" ; do

      ## Download PO files. Retain in a cache. Install to the $SPOOL dir.
      ## ex: devel-7.x-1.x     ==>  https://ftp.drupal.org/files/translations/7.x/devel/devel-7.x-1.x.fr.po                      ==>  SPOOL/devel-7.x-1.x.fr.po
      ## ex: devel-5.0.x       ==>  https://ftp.drupal.org/files/translations/all/devel/devel-5.0.x.fr.po                        ==>  SPOOL/devel-5.0.x.fr.po
      ## ex: drupal-7.x        ==>  https://ftp.drupal.org/files/translations/7.x/drupal/drupal-7.x.fr.po                        ==>  SPOOL/drupal-7.x.fr.po
      ## ex: backdropcms-1.23  ==>  https://localize.backdropcms.org/files/l10n_packager/all/backdropcms/backdropcms-1.23.fr.po  ==>  SPOOL/backdropcms-1.23.fr.po

      if [[ $TARGET =~ ([a-zA-Z0-9_]+)-(.*) ]]; then
        local PROJECT="${BASH_REMATCH[1]}"
        local VERSION="${BASH_REMATCH[2]}"

        local PO_SET=$( [[ "$VERSION" == *"7.x"* ]] && echo 7.x || echo all )
        local PO_URL="https://ftp.drupal.org/files/translations/${PO_SET}/${PROJECT}/${TARGET}.${NEW_LOCALE}.po"
        if [ "$PROJECT" = "backdropcms" ]; then
          PO_URL="https://localize.backdropcms.org/files/l10n_packager/all/backdropcms/backdropcms-${VERSION}.${NEW_LOCALE}.po"
        fi

        http_cache_setup "$PO_URL" "${CACHE_DIR}/drupal/translations/${TARGET}.${NEW_LOCALE}.po" "$TTL"
        cp "${CACHE_DIR}/drupal/translations/${TARGET}.${NEW_LOCALE}.po" "${SPOOL}/"
      fi
    done
  done
}

###############################################################################
## D7/BD - Load PO files
##
## Find any "*.po" files in BD (files/translations/*.po). Activate the associated languages and import the strings.
##
## usage: _drupalx_po_import <spool-dir>
function _drupalx_po_import() {
  local SPOOL="$1"

  ## Find any files named '*.XX.po` (eg `webform-4.x.fr.po`). The `XX` locale should be active.
  local NEW_LOCALES=$(find "${SPOOL}" -name '*.po' | sed 's;\(.*\)\.\(\w\w\)\.po;\2;' | sort -u)
  drush en -y locale
  if [ -z "$NEW_LOCALES" ]; then
    return
  fi
  drush language-add $NEW_LOCALES

  for NEW_LOCALE in $NEW_LOCALES ; do
    find "${SPOOL}" -name "*.${NEW_LOCALE}.po" | while read POFILE ; do
      drush language-import-translations "${NEW_LOCALE}" "${POFILE}"
    done
  done
}

###############################################################################
## Drupal -- Compute the name of the multi-site subdir
## Usage: _drupal_multisite_dir <url> <site-id>
## Note: <site-id> is 0 for the default/base site
function _drupal_multisite_dir() {
  if [ "$2" == "default" ]; then
    echo "default"
  else
    php -r '$p = parse_url($argv[1]); if (!empty($p["port"])) echo $p["port"] . "."; echo $p["host"];' -- "$1"
  fi
}

###############################################################################
## Drupal vX - Determine version of the codebase
## usage: _drupalx_version <x|x.y|x.y.z>
## example: VER=$(_drupalx_version x.y)
function _drupalx_version() {
  pushd "${WEB_ROOT}" >> /dev/null
    ## Is it Backdrop?
    if [ -e "web/core/modules/layout/layout.module" ]; then
      case "$1" in
        x)
          php -r 'require_once "web/core/includes/bootstrap.inc"; [$x]=explode(".",BACKDROP_VERSION); echo "$x\n";'
          return
          ;;

        x.y)
          php -r 'require_once "web/core/includes/bootstrap.inc"; [$x,$y]=explode(".",BACKDROP_VERSION); echo "$x.$y\n";'
          return
          ;;

        x.y-1)
          ## Find the "x.y" version, and rewind by 1. This is useful if you have checked out developmental/pre-release and need a resource from the prior stable.
          php -r 'require_once "web/core/includes/bootstrap.inc"; [$x,$y]=explode(".",BACKDROP_VERSION); $y--; echo "$x.$y\n";'
          return
          ;;

        x.y.z)
          php -r 'require_once "web/core/includes/bootstrap.inc"; [$x,$y,$z]=explode(".",BACKDROP_VERSION); echo "$x.$y.$z\n";'
          return
          ;;
      esac
    fi
    ## Is it Drupal 7?
    if [ -e "web/modules/system/system.module" ]; then
      case "$1" in
        x)
          php -r 'require_once "web/includes/bootstrap.inc"; [$x]=explode(".",VERSION); echo "$x\n";'
          return
          ;;

        x.y|x.y.z)
          ## Note: d7 releases don't use third digit, so x.y is a full/canonical version.
          php -r 'require_once "web/includes/bootstrap.inc"; [$x,$y]=explode(".",VERSION); echo "$x.$y\n";'
          return
          ;;

        x.y-1)
          ## Find the "x.y" version, and rewind by 1. This is useful if you have checked out developmental/pre-release and need a resource from the prior stable.
          php -r 'require_once "web/includes/bootstrap.inc"; [$x,$y]=explode(".",VERSION); $y--; echo "$x.$y\n";'
          return
          ;;
      esac
    fi
    ## Is it D8+?
    if [ -e "web/core/core.services.yml" ]; then
      case "$1" in
        x)
          php -r '$l = require "vendor/composer/installed.php"; [$x] = explode(".", $l["versions"]["drupal/core"]["pretty_version"]); echo "$x\n";'
          return
          ;;

        x.y)
          php -r '$l = require "vendor/composer/installed.php"; [$x,$y] = explode(".", $l["versions"]["drupal/core"]["pretty_version"]); echo "$x.$y\n";'
          return
          ;;

        x.y-1)
          php -r '$l = require "vendor/composer/installed.php"; [$x,$y] = explode(".", $l["versions"]["drupal/core"]["pretty_version"]); $y--; echo "$x.$y\n";'
          return
          ;;

        x.y.z)
          php -r '$l = require "vendor/composer/installed.php"; [$x,$y,$z] = explode(".", $l["versions"]["drupal/core"]["pretty_version"]); echo "$x.$y.$z\n";'
          return
          ;;

      esac
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
#!/usr/bin/env bash
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
    if php -r 'exit($argv[1] + file_get_contents($argv[2]) < time() ? 1 : 0);' -- $CACHE_TTL "$lastrun" ; then
      echo "SKIP: git_cache_setup '$url' $cachedir' (recently updated; ttl=$CACHE_TTL)"
      return
    fi
  fi

  cvutil_makeparent "$lock"
  if cvutil_php_nodbg pidlockfile.php "$lock" $$ $CACHE_LOCK_WAIT ; then
    php -r 'echo time();' > $lastrun
    if [ ! -d "$cachedir" ]; then
      ## clone
      echo "[[Initialize cache dir: $cachedir]]"
      cvutil_makeparent "$cachedir"
      timeout.php $SCM_TIMEOUT git clone --mirror "$url" "$cachedir"
    else
      ## update
      if [ -z "$OFFLINE" ]; then
        pushd "$cachedir" >> /dev/null
          git remote set-url origin "$url"
          timeout.php $SCM_TIMEOUT git fetch origin +refs/heads/*:refs/heads/* -u
        popd >> /dev/null
      else
        echo "[[Offline mode. Skip cache update: $cachedir]]"
      fi
    fi

    rm -f "$lock"
  else
    echo "ERROR: git_cache_setup '$url' '$cachdir': failed to acquire lock"
  fi
}


###############################################################################
## Initialize (or update) a cached copy of a git repo in $CACHE_DIR.
## Use a logical name for the cache dir.
##
## usage: git_cache_setup_id <cache-id>
## example: git_cache_setup_id civicrm/civicrm-core
## post-condition: $CACHE_DIR/$cache_id.git is a recently-updated clone
function git_cache_setup_id() {
  cvutil_assertvars git_cache_setup_id CACHE_DIR
  for cache_id in "$@" ; do
    local path="$CACHE_DIR/${cache_id}.git"
    local url=$(git_cache_map "$cache_id")
    if [[ -z "$url" ]]; then
      cvutil_fatal "Failed to find URL for cache ($cache_id)"
    fi
    git_cache_setup "$url" "$path"
  done
}

###############################################################################
## Update a common cache and then clone it
## usage: git_cache_clone <cache-id> <clone-options...>
## example: git_cache_clone civicrm/civicrm-core -b 5.99 --depth 1 /tmp/my-core
function git_cache_clone() {
  local cache_id="$1"
  shift
  git_cache_setup_id "$cache_id"
  git clone "$CACHE_DIR/${cache_id}.git" "$@"
  # TOOD: Might be nice to call git_cache_deref_remotes here, but then we need to know the output-dir
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
## Joomla -- Generate config files and setup database
## usage: joomla_install
function joomla_install() {
  local parent=$(dirname "$CMS_ROOT")
  local child=$(basename "$CMS_ROOT")
  joomla site:install -v \
    --www "$parent" \
    -L "$CMS_DB_USER:$CMS_DB_PASS" -H "$CMS_DB_HOST" -P "$CMS_DB_PORT" --mysql-database "$CMS_DB_NAME" \
    --overwrite \
    --skip-exists-check \
    "$child"
  cvutil_php_nodbg amp datadir "$CMS_ROOT/logs" "$CMS_ROOT/tmp"
}

###############################################################################
## Reset all the key details (username, password, email) for one of the
## Joomla user accounts.
##
## usage: joomla_reset_user <olduser> <newuser> <newpass> <newemail>
function joomla_reset_user() {
  env OLDUSER="$1" NEWUSER="$2" NEWPASS="$3" NEWMAIL="$4" amp sql -e -Ncms <<EOSQL
UPDATE j_users
SET username=@ENV[NEWUSER], password=md5(@ENV[NEWPASS]), email=@ENV[NEWMAIL]
WHERE username=@ENV[OLDUSER];
EOSQL
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
    if php -r 'exit($argv[1] + file_get_contents($argv[2]) < time() ? 1 : 0);' -- $CACHE_TTL "$lastrun" ; then
      echo "SKIP: svn_cache_setup '$url' $cachedir' (recently updated; ttl=$CACHE_TTL)"
      return
    fi
  fi

  cvutil_makeparent "$lock"
  if cvutil_php_nodbg pidlockfile.php "$lock" $$ $CACHE_LOCK_WAIT ; then
    php -r 'echo time();' > $lastrun
    if [ ! -d "$cachedir" ]; then
      ## clone
      echo "[[Initialize cache dir: $cachedir]]"
      cvutil_makeparent "$cachedir"
      timeout.php $SCM_TIMEOUT svn co "$url" "$cachedir"
    else
      ## update
      if [ -z "$OFFLINE" ]; then
        pushd "$cachedir" >> /dev/null
          timeout.php $SCM_TIMEOUT svn up
        popd >> /dev/null
      else
        echo "[[Offline mode. Skip cache update: $cachedir]]"
      fi
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

###############################################################################
## Update core/default caches
function default_cache_setup() {
  if [ -z "$OFFLINE" ]; then
    echo "[[Update caches]]"
    cvutil_assertvars default_cache_setup PRJDIR
    if [ -f "$PRJDIR/app/config/caches.sh" ]; then
      source "$PRJDIR/app/config/caches.sh"
    fi
  fi
}

function legacy_cache_warmup() {
  git_cache_setup_id civicrm/civicrm-{core,packages,backdrop,drupal,drupal-8,joomla,wordpress}
}

###############################################################################
## Edit a line in a file
## usage: cvutil_ed <file> <grep-match> <sed-replace>
function cvutil_ed() {
  file="$1"
  matches="$2"
  replacement="$3"
  if grep -q "$matches" "$file"  ; then
    mv "$file" "$file".bak
    sed "$replacement" < "$file".bak > "$file"
  fi
}
