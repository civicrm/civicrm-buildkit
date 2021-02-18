#!/bin/bash

###############################################################################
## Common/standard defaults

[ -z "$SITE_TOKEN" ]         && SITE_TOKEN=$(cvutil_makepasswd 16)
[ -z "$CIVI_CRED_KEY" ]      && CIVI_CRED_KEY=$(cvutil_makepasswd 32)
[ -z "$CIVI_SIGN_KEY" ]      && CIVI_SIGN_KEY=$(cvutil_makepasswd 32)
[ -z "$CIVI_SITE_KEY" ]      && CIVI_SITE_KEY=$(cvutil_makepasswd 16)
[ -z "$ADMIN_PASS" ]         && ADMIN_PASS=$(cvutil_makepasswd 12)
[ -z "$DEMO_PASS" ]          && DEMO_PASS=$(cvutil_makepasswd 12)
[ -z "$SITE_TYPE" ]          && SITE_TYPE="$SITE_NAME"
[ -z "$CMS_TITLE" ]          && CMS_TITLE="$SITE_NAME"
[ -z "$SNAPSHOT_NAME" ]      && SNAPSHOT_NAME="$SITE_NAME"

## Note: "WEB_ROOT" is actually the root of the build's code, and "CMS_ROOT" is the HTTP document root.
## Now-a-days, most builds set "CMS_ROOT=$WEB_ROOT/web"
[ -z "$WEB_ROOT" ]           && WEB_ROOT="$BLDDIR/$SITE_NAME"
[ -z "$CMS_ROOT" ]           && CMS_ROOT="$WEB_ROOT"

CIVIBUILD_PATH="$CIVIBUILD_PATH:$PRJDIR/app/config"
[ -z "$SITE_CONFIG_DIR" ]    && SITE_CONFIG_DIR=$(cvutil_path_search "$SITE_TYPE" "$CIVIBUILD_PATH")

if [ -z "$CMS_URL" ]; then
  if [ "%AUTO%" == "$URL_TEMPLATE" ]; then
    if [ -n "$IS_ALIAS" ]; then
      CMS_URL=$( echo "http://%SITE_NAME%.test" | sed "s;%SITE_NAME%;$SITE_NAME;g" )
    # else: leave CMS_URL empty
    fi
  else
    CMS_URL=$( echo "$URL_TEMPLATE" | sed "s;%SITE_NAME%;$SITE_NAME;g" )
  fi
fi

if [ -z "$COMPOSER_MEMORY_LIMIT" ]; then
  COMPOSER_MEMORY_LIMIT=-1
  export COMPOSER_MEMORY_LIMIT
fi

###############################################################################
## Defaults for traditional file-structure, in which user clones repo and
## data is written to "./app" and "./build"
if [ -z "$CIVIBUILD_HOME" ]; then

  [ -z "$CACHE_DIR" ]          && CACHE_DIR="$TMPDIR/git-cache"
  [ -z "$SNAPSHOT_DIR" ]       && SNAPSHOT_DIR="$PRJDIR/app/snapshot"

  ## Note: Originally, all common build-types lacked a 'web/' folder, so
  ## auxiliary data needed to go elsewhere.

  [ -z "$PRIVATE_ROOT" ]       && PRIVATE_ROOT="$PRJDIR/app/private/$SITE_NAME"
  [ -z "$CLONE_ROOT" ]         && CLONE_ROOT="$PRJDIR/app/clone/$SITE_NAME/$SITE_ID"
  [ -z "$CLONE_DIR" ]          && CLONE_DIR="$CLONE_ROOT/$CLONE_ID"
  [ -z "$UPGRADE_LOG_DIR" ]    && UPGRADE_LOG_DIR="$PRJDIR/app/debug/$SITE_NAME"

  [ -z "$CIVICRM_GENCODE_DIGEST" ] && CIVICRM_GENCODE_DIGEST="$TMPDIR/$SITE_NAME-gencode.md5"
  [ -z "$SHOW_LAST_SCAN" ]     && SHOW_LAST_SCAN="$TMPDIR/git-scan-${SITE_NAME}-last.json"
  [ -z "$SHOW_NEW_SCAN" ]      && SHOW_NEW_SCAN="$TMPDIR/git-scan-${SITE_NAME}-new.json"

###############################################################################
## Defaults for system-wide installs, in which scripts are placed in a shared folder
## and data is written to some configureable "HOME"

elif [ -n "$CIVIBUILD_HOME" ]; then

  [ -z "$CACHE_DIR" ]          && CACHE_DIR="$CIVIBUILD_HOME/.civibuild/cache"
  [ -z "$SNAPSHOT_DIR" ]       && SNAPSHOT_DIR="$CIVIBUILD_HOME/.civibuild/snapshot"

  ## Note: Now-a-days, all common build-types point HTTTPD to 'WEB_ROOT/web/' folder, so we can
  ## put auxiliary data adjacent to that.

  [ -z "$PRIVATE_ROOT" ]       && PRIVATE_ROOT="$WEB_ROOT/.civibuild/private"
  [ -z "$CLONE_ROOT" ]         && CLONE_ROOT="$WEB_ROOT/.civibuild/clone/$SITE_ID"
  [ -z "$CLONE_DIR" ]          && CLONE_DIR="$CLONE_ROOT/$CLONE_ID"
  [ -z "$UPGRADE_LOG_DIR" ]    && UPGRADE_LOG_DIR="$WEB_ROOT/.civibuild/debug"

  [ -z "$CIVICRM_GENCODE_DIGEST" ] && CIVICRM_GENCODE_DIGEST="$WEB_ROOT/.civibuild/gencode.md5"
  [ -z "$SHOW_LAST_SCAN" ]     && SHOW_LAST_SCAN="$WEB_ROOT/.civibuild/git-scan-last.json"
  [ -z "$SHOW_NEW_SCAN" ]      && SHOW_NEW_SCAN="$WEB_ROOT/.civibuild/git-scan-new.json"

fi

###############################################################################
## Wrap-up - common defaults which are derived from some other default

if [ "default" == "$SITE_ID" ]; then
  [ -z "$CIVI_SQL"  ]        && CIVI_SQL="$SNAPSHOT_DIR/$SNAPSHOT_NAME/civi.sql.gz"
  [ -z "$CMS_SQL" ]          && CMS_SQL="$SNAPSHOT_DIR/$SNAPSHOT_NAME/cms.sql.gz"
else
  [ -z "$CIVI_SQL"  ]        && CIVI_SQL="$SNAPSHOT_DIR/$SNAPSHOT_NAME--$SITE_ID/civi.sql.gz"
  [ -z "$CMS_SQL" ]          && CMS_SQL="$SNAPSHOT_DIR/$SNAPSHOT_NAME--$SITE_ID/cms.sql.gz"
fi

export CIVICRM_GENCODE_DIGEST
