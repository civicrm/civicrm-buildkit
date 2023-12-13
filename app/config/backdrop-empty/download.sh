#!/usr/bin/env bash

## download.sh -- Download Backdrop and CiviCRM

###############################################################################

git_cache_setup_id "backdrop/backdrop"

###############################################################################

[ -z "$CMS_VERSION" ] && CMS_VERSION="1.x"
[ -z "$CIVI_VERSION" ] && CIVI_VERSION=none

backdrop_download
pushd "$WEB_ROOT/web" >> /dev/null
  BACKDROP_LANG_VER=$( [ "$CMS_VERSION" = "1.x" ] && _drupalx_version x.y-1 || _drupalx_version x.y )
  backdrop_po_download "${CIVICRM_LOCALES:-de_DE}" "backdropcms-${BACKDROP_LANG_VER}"
popd >> /dev/null
