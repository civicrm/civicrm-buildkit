#!/bin/bash

## download.sh -- Download Backdrop and CiviCRM

###############################################################################

git_cache_setup "https://github.com/backdrop/backdrop.git" "$CACHE_DIR/backdrop/backdrop.git"

[ -n "$CMS_VERSION" ] && CMS_VERSION="1.x"
[ -z "$CIVI_VERSION" ] && CIVI_VERSION=none

backdrop_download
