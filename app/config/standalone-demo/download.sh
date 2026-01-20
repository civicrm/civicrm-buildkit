#!/usr/bin/env bash

## download.sh -- Download CiviCRM core and configure it for standalone development

###############################################################################

[ -z "$CMS_VERSION" ] && CMS_VERSION=master
## Hmm, not really used...

mkdir -p "$WEB_ROOT/web"

pushd "$WEB_ROOT/web"
  amp datadir "./private" "./public" "./ext"

  git_cache_clone civicrm/civicrm-core                             -b "$CIVI_VERSION" core
  git_cache_clone civicrm/civicrm-packages                         -b "$CIVI_VERSION" core/packages

  civicrm_l10n_setup private

  # add demo specific extensions
  git_cache_clone civicrm/standalone_demo                         ext/standalone_demo
  git_cache_clone civicrm/search_kit_report_starter_pack          ext/search_kit_report_starter_pack
popd

civibuild_apply_user_extras
CIVI_CORE="$WEB_ROOT/web/core" civicrm_composer_install
