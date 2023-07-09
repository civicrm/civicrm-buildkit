#!/usr/bin/env bash

## download.sh -- Download CiviCRM core and configure it for standalone development

###############################################################################

[ -z "$CMS_VERSION" ] && CMS_VERSION=master
## Hmm, not really used...

mkdir -p "$WEB_ROOT" "$WEB_ROOT/web" "$WEB_ROOT/web/uploads" "$WEB_ROOT/data"

pushd "$WEB_ROOT"
  amp datadir "./data" "./web/uploads"

  git clone ${CACHE_DIR}/civicrm/civicrm-core.git                     -b "$CIVI_VERSION" web/core
  git clone ${CACHE_DIR}/civicrm/civicrm-packages.git                 -b "$CIVI_VERSION" web/core/packages
popd

pushd "$WEB_ROOT/web/core"
  composer install
popd
