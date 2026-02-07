#!/usr/bin/env bash

## download.sh -- Download Bluebird
##
## Based on wiki `Installing_Bluebird_on_Windows_Subsystem_for_Linux_(WSL)`
##
## Note: The wiki page describes "APP_ROOT". In civibuild, the equivalent
## variable is called "WEB_ROOT". ("APP_ROOT" is a better name... but it's
## "WEB_ROOT" here...)

###############################################################################

[ -z "$CMS_VERSION" ] && CMS_VERSION=dev

## Preemptively set file-permissions for modification by web-server.
## (This *might* be overkill, but let's get things working before forming that opinion...)
amp data "$WEB_ROOT"

## Checkout the git repos
git_cache_setup "https://github.com/nysenate/Bluebird-CRM.git" "$CACHE_DIR/nysenate/Bluebird-CRM.git"
git clone "$CACHE_DIR/nysenate/Bluebird-CRM.git" "$WEB_ROOT"

pushd "$WEB_ROOT"
  git_checkout "$CMS_VERSION"

  # FIXME: cp $HOME/Downloads/bluebird/senate_test_*sql templates/sql/

  ## Work-around: In buildkit-nix, Apache config has strong prefercence for "web/" folder.
  ln -sf drupal web

  ## It looks like this might be necessary for the 'Old' subdir.
  ## But the main scripts are already 755.
  # find scripts -name '*.sh' -exec chmod 755 {} \;

  ## Something like this appears in most Civi build-types. But if vendor/ is committed to git, then maybe not.
  #pushd sites/all/modules
  #  civibuild_apply_user_extras
  #  CIVI_CORE="$PWD/civicrm" civicrm_composer_install
  #popd

popd
