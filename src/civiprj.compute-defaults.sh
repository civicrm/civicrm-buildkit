#!/bin/bash

[ -z "$GIT_CACHE_DIR" ]      && GIT_CACHE_DIR="$TMPDIR/git-cache"
[ -z "$WEB_ROOT" ]           && WEB_ROOT="$PRJDIR/build/$SITE_NAME"
[ -z "$CIVI_SITE_KEY" ]      && CIVI_SITE_KEY=$(cvutil_makepasswd 16)
[ -z "$ADMIN_PASS" ]         && ADMIN_PASS=$(cvutil_makepasswd 12)
[ -z "$DEMO_PASS" ]          && DEMO_PASS=$(cvutil_makepasswd 12)
[ -z "$SITE_TYPE" ]          && SITE_TYPE="$SITE_NAME"
[ -z "$CMS_TITLE" ]          && CMS_TITLE="$SITE_NAME"
#[ -z "$CMS_HOSTNAME" ]       && CMS_HOSTNAME=$(php -r '$p = parse_url($argv[1]); echo $p["host"];' "$CMS_URL")
#[ -z "$CMS_PORT" ]           && CMS_PORT=$(php -r '$p = parse_url($argv[1]); echo $p["port"];' "$CMS_URL")
[ -z "$CIVI_SQL" ]           && CIVI_SQL="$PRJDIR/app/snapshot/$SITE_NAME/civi.sql.gz"
[ -z "$CMS_SQL" ]            && CMS_SQL="$PRJDIR/app/snapshot/$SITE_NAME/cms.sql.gz"
[ -z "$SITE_CONFIG_DIR" ]    && SITE_CONFIG_DIR="$PRJDIR/app/config/$SITE_TYPE"
[ -z "$FACL_USERS" ]         && FACL_USERS="www-data $(whoami)"
