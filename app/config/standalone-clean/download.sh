#!/usr/bin/env bash

## download.sh -- Download CiviCRM core and configure it for standalone development

###############################################################################

[ -z "$CMS_VERSION" ] && CMS_VERSION=master
## Hmm, not really used...

mkdir -p "$WEB_ROOT/web"

pushd "$WEB_ROOT/web"
  amp datadir "./private" "./public" "./ext"

  if [[ $CIVI_VERSION = *esr* ]]; then
    # For civicrm-packages we need a downgraded non-ESR-version as ESR does not maintain civicrm-packages.
    # example: 6.16.8+esr -> 6.16.0. 
    DOWNGRADED_CIVI_VERSION_WITHOUT_SUFFIX=$(echo "$CIVI_VERSION" | sed 's/[0-9]+esr/0/') 
    git_cache_clone esr/core                                         -b "$CIVI_VERSION" core
    git_cache_clone civicrm/civicrm-packages                         -b "$DOWNGRADED_CIVI_VERSION_WITHOUT_SUFFIX" core/packages
  else
    git_cache_clone civicrm/civicrm-core                             -b "$CIVI_VERSION" core
    git_cache_clone civicrm/civicrm-packages                         -b "$CIVI_VERSION" core/packages
  fi

  civicrm_l10n_setup private
popd

civibuild_apply_user_extras
CIVI_CORE="$WEB_ROOT/web/core" civicrm_composer_install
