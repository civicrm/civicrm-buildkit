#!/bin/bash

## download.sh -- Download Backdrop and CiviCRM

###############################################################################

git_cache_setup "https://github.com/backdrop/backdrop.git" "$CACHE_DIR/backdrop/backdrop.git"

[ -n "$CMS_VERSION" ] && CMS_VERSION="1.x"
[ -z "$CIVI_VERSION" ] && CIVI_VERSION=none

echo "[[Download Backdrop]]"
mkdir "$WEB_ROOT"
git clone "$CACHE_DIR/backdrop/backdrop.git" "$WEB_ROOT/web"
