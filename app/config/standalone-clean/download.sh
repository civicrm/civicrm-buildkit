#!/usr/bin/env bash

## download.sh -- Download CiviCRM core and configure it for standalone development

###############################################################################

[ -z "$CMS_VERSION" ] && CMS_VERSION=master
## Hmm, not really used...

mkdir -p "$WEB_ROOT/web"

pushd "$WEB_ROOT/web"
  amp datadir "./private" "./public" "./ext"

  if [[ $CIVI_VERSION = *esr* ]]; then
    git_cache_clone esr/core                                         -b "$CIVI_VERSION" core
    git_cache_clone esr/packages                                     -b "$CIVI_VERSION" core/packages
  else
    git_cache_clone civicrm/civicrm-core                             -b "$CIVI_VERSION" core
    git_cache_clone civicrm/civicrm-packages                         -b "$CIVI_VERSION" core/packages
  fi

  civicrm_l10n_setup private
popd

civibuild_apply_user_extras
CIVI_CORE="$WEB_ROOT/web/core" civicrm_composer_install
