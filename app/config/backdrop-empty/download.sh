#!/bin/bash

## download.sh -- Download Backdrop and CiviCRM

###############################################################################

git_cache_setup "https://github.com/backdrop/backdrop.git" "$CACHE_DIR/backdrop/backdrop.git"

[ -z "$CMS_VERSION" ] && CMS_VERSION="1.x"
[ -z "$CIVI_VERSION" ] && CIVI_VERSION=none

backdrop_download
pushd "$WEB_ROOT/web" >> /dev/null
  backdrop_po_download "${CIVICRM_LOCALES:-de_DE}" backdropcms-$(_backdrop_version x.y-1)
  ## Ugh. When we have `backdrop.git@master`, then the BD translations may not have started yet, so the PO download will fail.
  ## Downloading the prior version should always work... and it should usually be close enough...
popd >> /dev/null
