#!/usr/bin/env bash

## download.sh -- Download Standalone project and CiviCRM core

###############################################################################

[ -z "$CIVI_VERSION" ] && CIVI_VERSION=master
[ -z "$CMS_VERSION" ] && CMS_VERSION=master
## Interpreted as tag/branch of "civicrm-standalone.git".
## May use git remotes to referencing Github ("{user}/{branch}").

git clone https://github.com/civicrm/civicrm-standalone "$WEB_ROOT/web"

pushd "$WEB_ROOT/web"
  if [[ "$CMS_VERSION" == *"/"* ]]; then
    _git_owner=$(dirname "$CMS_VERSION")
    git remote add "$_git_owner" "https://github.com/${_git_owner}/civicrm-standalone.git"
    git fetch "$_git_owner"
  fi
  git checkout "$CMS_VERSION"

  amp datadir "./private" "./public" "./ext"

  ## `civicrm-standalone.git:composer.json` is hard-coded to master. If user requests anything else, then we must update it.
  if [ "$CIVI_VERSION" == "master" ]; then
    composer install
  else
    CIVI_VERSION_COMP=$(civicrm_composer_ver "$CIVI_VERSION")
    composer require civicrm/civicrm-{core,packages}:"$CIVI_VERSION_COMP" --prefer-source
  fi

  composer civicrm:publish
popd
