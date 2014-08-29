#!/bin/bash

[ -z "$CACHE_DIR" ]          && CACHE_DIR="$TMPDIR/git-cache"
[ -z "$WEB_ROOT" ]           && WEB_ROOT="$BLDDIR/$SITE_NAME"
[ -z "$CMS_ROOT" ]           && CMS_ROOT="$WEB_ROOT"
[ -z "$PRIVATE_ROOT" ]       && PRIVATE_ROOT="$PRJDIR/app/private/$SITE_NAME"
[ -z "$CLONE_ROOT" ]         && CLONE_ROOT="$PRJDIR/app/clone/$SITE_NAME/$SITE_ID"
[ -z "$CLONE_DIR" ]          && CLONE_DIR="$CLONE_ROOT/$CLONE_ID"
[ -z "$UPGRADE_LOG_DIR" ]    && UPGRADE_LOG_DIR="$PRJDIR/app/debug/$SITE_NAME"
[ -z "$CIVI_SITE_KEY" ]      && CIVI_SITE_KEY=$(cvutil_makepasswd 16)
[ -z "$ADMIN_PASS" ]         && ADMIN_PASS=$(cvutil_makepasswd 12)
[ -z "$DEMO_PASS" ]          && DEMO_PASS=$(cvutil_makepasswd 12)
[ -z "$SITE_TYPE" ]          && SITE_TYPE="$SITE_NAME"
[ -z "$CMS_TITLE" ]          && CMS_TITLE="$SITE_NAME"
[ -z "$SNAPSHOT_NAME" ]      && SNAPSHOT_NAME="$SITE_NAME"
#[ -z "$CMS_HOSTNAME" ]       && CMS_HOSTNAME=$(php -r '$p = parse_url($argv[1]); echo $p["host"];' "$CMS_URL")
#[ -z "$CMS_PORT" ]           && CMS_PORT=$(php -r '$p = parse_url($argv[1]); echo $p["port"];' "$CMS_URL")
[ -z "$SNAPSHOT_DIR" ]       && SNAPSHOT_DIR="$PRJDIR/app/snapshot"
if [ "default" == "$SITE_ID" ]; then
  [ -z "$CIVI_SQL"  ]        && CIVI_SQL="$SNAPSHOT_DIR/$SNAPSHOT_NAME/civi.sql.gz"
  [ -z "$CMS_SQL" ]          && CMS_SQL="$SNAPSHOT_DIR/$SNAPSHOT_NAME/cms.sql.gz"
else
  [ -z "$CIVI_SQL"  ]        && CIVI_SQL="$SNAPSHOT_DIR/$SNAPSHOT_NAME--$SITE_ID/civi.sql.gz"
  [ -z "$CMS_SQL" ]          && CMS_SQL="$SNAPSHOT_DIR/$SNAPSHOT_NAME--$SITE_ID/cms.sql.gz"
fi
[ -z "$SITE_CONFIG_DIR" ]    && SITE_CONFIG_DIR="$PRJDIR/app/config/$SITE_TYPE"
[ -z "$CIVICRM_GENCODE_DIGEST" ] && CIVICRM_GENCODE_DIGEST="$TMPDIR/$SITE_NAME-gencode.md5"
[ -z "$SHOW_LAST_SCAN" ]     && SHOW_LAST_SCAN="$TMPDIR/git-scan-${SITE_NAME}-last.json"
[ -z "$SHOW_NEW_SCAN" ]      && SHOW_NEW_SCAN="$TMPDIR/git-scan-${SITE_NAME}-new.json"
[ -z "$SITE_TOKEN" ]         && SITE_TOKEN=$(cvutil_makepasswd 16)

export CIVICRM_GENCODE_DIGEST
