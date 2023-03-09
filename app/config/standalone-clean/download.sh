#!/bin/bash

## download.sh -- Download Standalone project and CiviCRM core

###############################################################################

[ -z "$CMS_VERSION" ] && CMS_VERSION=master
## Interpreted as tag/branch of "civicrm-standalone.git".
## May use git remotes to referencing Github ("{user}/{branch}").

git clone https://github.com/civicrm/civicrm-standalone "$WEB_ROOT"

pushd "$WEB_ROOT"
  if [[ "$CMS_VERSION" == *"/"* ]]; then
    _git_owner=$(dirname "$CMS_VERSION")
    git remote add "$_git_owner" "https://github.com/${_git_owner}/civicrm-standalone.git"
    git fetch "$_git_owner"
  fi
  git checkout "$CMS_VERSION"

  amp datadir "./data" "./web/uploads"
  composer install
  composer civicrm:publish
popd
