#!/bin/bash
set +x
git_cache_setup "https://git.wikimedia.org/git/wikimedia/fundraising/crm.git" "$CACHE_DIR/wikimedia/fundraising/crm.git"
git_cache_setup "https://gerrit.wikimedia.org/r/wikimedia/fundraising/crm/civicrm.git" "$CACHE_DIR/wikimedia/fundraising/civicrm.git"
git_cache_setup "https://gerrit.wikimedia.org/r/wikimedia/fundraising/crm/drupal.git" "$CACHE_DIR/wikimedia/fundraising/drupal.git"
set -x

# git clone --recursive https://git.wikimedia.org/git/wikimedia/fundraising/crm.git  fundraising-crm
git clone "$CACHE_DIR/wikimedia/fundraising/crm.git" "$WEB_ROOT"

pushd "$WEB_ROOT"
  git clone "$CACHE_DIR/wikimedia/fundraising/civicrm.git" civicrm
  git clone "$CACHE_DIR/wikimedia/fundraising/drupal.git" drupal

  ## Reset the .git/config to match remotes in .gitmodules
  git submodule sync

  ## Checkout the proper revisions
  git submodule update
popd