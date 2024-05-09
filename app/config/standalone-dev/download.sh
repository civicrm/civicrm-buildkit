#!/usr/bin/env bash

## download.sh -- Download CiviCRM core and configure it for standalone development

###############################################################################

[ -z "$CMS_VERSION" ] && CMS_VERSION=master
## Hmm, not really used...

mkdir -p "$WEB_ROOT" "$WEB_ROOT/web" "$WEB_ROOT/web/upload" "$WEB_ROOT/data"

pushd "$WEB_ROOT"
  amp datadir "./data" "./web/upload"

  git_cache_clone civicrm/civicrm-core                             -b "$CIVI_VERSION" web/core
  git_cache_clone civicrm/civicrm-packages                         -b "$CIVI_VERSION" web/core/packages

  civicrm_l10n_setup web/core
popd

civibuild_apply_user_extras
pushd "$WEB_ROOT/web/core"
  composer install
popd
