#!/usr/bin/env bash

###############################################################################
## Display usage message
function civibuild_app_usage() {
  if [ -f "$PRJDIR/src/help/$ACTION.hlp" ]; then
    cat "$PRJDIR/src/help/$ACTION.hlp"
  else
    cat "$PRJDIR/src/help/default.hlp"
  fi

  exit 99;
}

###############################################################################
## Run an external script (based on the site-type)
## usage: civibuild_app_run <script-name>
function civibuild_app_run() {
  local _shellopt="$-"

  MAIN_SCRIPT="${SITE_CONFIG_DIR}/$1.sh"
  [ ! -f "$MAIN_SCRIPT" ] && echo "ERROR: Missing main script ($MAIN_SCRIPT)" && exit 98

  echo "[[Execute $MAIN_SCRIPT]]"

  set -e
  if [[ -n "$VERBOSE" ]]; then
    set -x
  fi

  source "$MAIN_SCRIPT"

  set -${_shellopt}
}

###############################################################################
## Run an external script (based on the site-type)
## usage: civibuild_app_run_optional <script-name>
function civibuild_app_run_optional() {
  MAIN_SCRIPT="${SITE_CONFIG_DIR}/$1.sh"
  if [ -f "$MAIN_SCRIPT" ]; then
    #echo "[[Execute $MAIN_SCRIPT]]"
    #set -ex
    source "$MAIN_SCRIPT"
    #set +ex
  fi
}

###############################################################################
## Run the download scripts if necessary
## i.e. run them if FORCE_DOWNLOAD or if
## the folder doesn't exist
function civibuild_app_download() {
  cvutil_assertvars civibuild_app_download WEB_ROOT PRJDIR CACHE_DIR SITE_NAME SITE_TYPE

  echo "[[Download $SITE_NAME (type '$SITE_TYPE' in '$WEB_ROOT')]]"

  if [ -n "$FORCE_DOWNLOAD" -a -d "$WEB_ROOT" ]; then
    if cvutil_confirm "About to re-download \"$WEB_ROOT\". Are you sure you want destroy existing files? [y/N] " n y; then
      chmod u+w -R "$WEB_ROOT"
      rm -rf "$WEB_ROOT"
    else
      echo "Aborted" 1>&2
      exit 1
    fi
  fi

  if [ ! -d "$WEB_ROOT" ]; then
    IS_INSTALLED=
    pushd "$PRJDIR" > /dev/null
      default_cache_setup
      civibuild_app_run download
      git_cache_deref_remotes "$CACHE_DIR" "$WEB_ROOT"
      if [ -n "$EXTRA_DLS" ]; then
        pushd "$WEB_ROOT" >> /dev/null
          if ! extract-url -v -d '|' "$EXTRA_DLS" ; then
            echo "Failed to extract extra archives"
            exit 94
          fi
        popd >> /dev/null
      fi
      if [ -n "$PATCHES" ]; then
        pushd "$WEB_ROOT" >> /dev/null
          if ! git scan automerge --rebuild --url-split='|' "$PATCHES" --passthru='--ignore-whitespace' ; then
            echo "Failed to apply patch(es)"
            exit 95
          fi
        popd >> /dev/null
      fi
    popd > /dev/null
    if [ ! -d "$WEB_ROOT" ]; then
      echo "Download failed to create directory"
      exit 97
    fi
  else
    echo "Already downloaded ${SITE_NAME}"
  fi
}

###############################################################################
## Run the installation scripts if necessary
## i.e. run them if FORCE_INSTALL or if the
## site wasn't previously installed
function civibuild_app_install() {
  cvutil_assertvars civibuild_app_install WEB_ROOT PRIVATE_ROOT SITE_NAME SITE_ID SITE_TYPE

  echo "[[Install $SITE_NAME/$SITE_ID (type '$SITE_TYPE' in '$WEB_ROOT')]]"

  if [ ! -d "$WEB_ROOT" ]; then
    echo "Cannot install: missing root '$WEB_ROOT'"
    exit 96
  fi

  if [ -z "$FORCE_INSTALL" -a -n "$IS_INSTALLED" ]; then
    if cvutil_confirm "About to re-install \"$WEB_ROOT\". Are you sure you want destroy existing data? [y/N] " n y; then
      FORCE_INSTALL=1
    else
      echo "Aborted" 1>&2
      exit 1
    fi
  fi

  if [ -n "$FORCE_INSTALL" -a -n "$IS_INSTALLED" ]; then
    pushd "$WEB_ROOT" > /dev/null
      civibuild_app_run uninstall
    popd > /dev/null
    if [ -d "$PRIVATE_ROOT" ]; then
      rm -rf "$PRIVATE_ROOT"
    fi
  fi

  if [ -n "$FORCE_INSTALL" -o -z "$IS_INSTALLED" ]; then
    pushd "$WEB_ROOT" > /dev/null
      civibuild_app_run install
    popd > /dev/null
    amp_snapshot_create
    IS_INSTALLED=1
  else
    echo "Already installed ${SITE_NAME}/${SITE_ID}"
  fi

  if [ -n "$EXT_DLS" ]; then
    pushd "$WEB_ROOT" >> /dev/null
      if ! cv dl -k $EXT_DLS ; then
        echo "Failed to download or enable extensions ($EXT_DLS)"
        exit 92
      fi
    popd >> /dev/null
  fi

  _amp_snapshot_restore_test
}

###############################################################################
## Write any persistent settings to disk
function civibuild_app_save() {
  cvutil_assertvars civibuild_app_save BLDDIR SITE_NAME SITE_ID PERSISTENT_VARS

  if [ "$SITE_ID" == "default" ]; then
    cvutil_save "${BLDDIR}/${SITE_NAME}.sh" $PERSISTENT_VARS
  else
    cvutil_save "${BLDDIR}/${SITE_NAME}.${SITE_ID}.sh" $PERSISTENT_VARS
  fi
}

###############################################################################
function civibuild_app_show() {
  if [ -n "$SHOW_HTML" ]; then
    civibuild_app_show_html
  fi

  if [ -n "$SHOW_FULL_BUILD_CONF" ]; then
    civibuild_app_show_summary $PERSISTENT_VARS
  else
    civibuild_app_show_summary \
      CMS_ROOT CMS_URL CMS_DB_DSN \
      CIVI_DB_DSN TEST_DB_DSN \
      ADMIN_USER ADMIN_PASS DEMO_USER DEMO_PASS
  fi
}

function civibuild_app_show_summary() {
# Don't follow assertvars pattern of "$@" because we want to report even if vars are empty:
  cvutil_assertvars civibuild_app_show_summary "SITE_NAME" "SITE_ID"
  cvutil_summary "[[Show site summary ($SITE_NAME/$SITE_ID)]]" $@
  civibuild_app_run_optional show
  echo "[[General notes]]"
  echo " - You may need to restart httpd."
  echo " - You may need to add the hostname and IP to /etc/hosts or DNS."
}

function civibuild_app_show_html() {
  echo "[[Generate HTML ($SHOW_HTML)]]"
  cvutil_assertvars civibuild_app_show PERSISTENT_VARS SHOW_LAST_SCAN SHOW_NEW_SCAN SHOW_HTML SITE_NAME WEB_ROOT
  if [ ! -f "$SHOW_LAST_SCAN" ]; then
    cvutil_makeparent "$SHOW_LAST_SCAN"
    echo '{"details":[],"root":""}' > "$SHOW_LAST_SCAN"
  fi

  cvutil_makeparent "$SHOW_NEW_SCAN"
  pushd "$WEB_ROOT"
    git scan export > "$SHOW_NEW_SCAN"
  popd

  cvutil_export $PERSISTENT_VARS SHOW_LAST_SCAN SHOW_NEW_SCAN SITE_NAME

  cvutil_mkdir "$SHOW_HTML"
  php $PRJDIR/src/views/show-index.php > "$SHOW_HTML/index.html"
  cat "$SHOW_LAST_SCAN" > "$SHOW_HTML/git-scan.last.json"
  cat "$SHOW_NEW_SCAN" > "$SHOW_HTML/git-scan.new.json"
  cat "$SHOW_LAST_SCAN" | php -r 'print_r(json_decode(file_get_contents("php://stdin"),TRUE));' > "$SHOW_HTML/git-scan.last.txt"
  cat "$SHOW_NEW_SCAN" | php -r 'print_r(json_decode(file_get_contents("php://stdin"),TRUE));' > "$SHOW_HTML/git-scan.new.txt"
}

###############################################################################
function civibuild_app_clone_create() {
  if [ -z "$CLONE_ID" ]; then
    echo "missing required parameter: --clone-id 123"
    exit 1
  fi
  cvutil_assertvars civibuild_app_clone_create CLONE_DIR CLONE_ID CMS_SQL CIVI_SQL

  if [ ! -d "$CLONE_DIR" -o "$CMS_SQL" -nt "$CLONE_DIR/.mark" -o "$CMS_SQL" -nt "$CLONE_DIR/.mark" ]; then
    IS_NEW=1
  fi

  if [ -n "$IS_NEW" -o -n "$FORCE_INSTALL" ]; then
    cvutil_mkdir "$CLONE_DIR"
    pushd $CLONE_DIR >> /dev/null
      _amp_install_clone cms CLONE_CMS
      _amp_snapshot_restore_clone CLONE_CMS "$CMS_SQL"
      _amp_install_clone civi CLONE_CIVI
      _amp_snapshot_restore_clone CLONE_CIVI "$CIVI_SQL"
    popd >> /dev/null
    touch "$CLONE_DIR/.mark"
  else
    #echo "[[Clone already exists ($CLONE_DIR). Snapshots appear unchanged. Use --force to re-create]]"
    echo "[[Clone already exists ($CLONE_DIR). Use --force to re-create]]"
    civibuild_app_clone_import
  fi
}

###############################################################################
## Destroy a clone
function civibuild_app_clone_destroy() {
  if [ -z $CLONE_ID ]; then
    cvutil_assertvars civibuild_app_clone_destroy CLONE_ROOT
    if [ -d "$CLONE_ROOT" ]; then
      rm -rf "$CLONE_ROOT"
    fi
  else
    cvutil_assertvars civibuild_app_clone_destroy CLONE_DIR
    if [ -d "$CLONE_DIR" ]; then
      rm -rf "$CLONE_DIR"
    fi
  fi
  amp cleanup
}

###############################################################################
## Load DB details for a clone
function civibuild_app_clone_import() {
  if [ -z "$CLONE_ID" ]; then
    echo "missing required parameter: --clone-id 123"
    exit 1
  fi
  cvutil_assertvars civibuild_app_clone_create CLONE_DIR CLONE_ID
  _amp_import "$CLONE_DIR" cms CLONE_CMS
  _amp_import "$CLONE_DIR" civi CLONE_CIVI
}

###############################################################################
## Display DB details for a clone
function civibuild_app_clone_show() {
  cvutil_assertvars civibuild_app_clone_show SITE_NAME SITE_ID CLONE_ID
  cvutil_summary "[[Show clone summary ($SITE_NAME/$SITE_ID/$CLONE_ID)]]" \
    CLONE_DIR \
    CLONE_CMS_DB_DSN \
    CLONE_CIVI_DB_DSN
}
