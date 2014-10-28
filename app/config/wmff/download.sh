#!/bin/bash
set +x
git_cache_setup "https://gerrit.wikimedia.org/r/mediawiki/extensions/DonationInterface.git" "$CACHE_DIR/wikimedia/fundraising/DonationInterface.git"
git_cache_setup "https://gerrit.wikimedia.org/r/wikimedia/fundraising/crm.git" "$CACHE_DIR/wikimedia/fundraising/crm.git"
git_cache_setup "https://gerrit.wikimedia.org/r/wikimedia/fundraising/crm/civicrm.git" "$CACHE_DIR/wikimedia/fundraising/civicrm.git"
git_cache_setup "https://gerrit.wikimedia.org/r/wikimedia/fundraising/crm/drupal.git" "$CACHE_DIR/wikimedia/fundraising/drupal.git"
git_cache_setup "https://gerrit.wikimedia.org/r/wikimedia/fundraising/phpmailer.git" "$CACHE_DIR/wikimedia/fundraising/phpmailer.git"
git_cache_setup "https://gerrit.wikimedia.org/r/wikimedia/fundraising/twig.git" "$CACHE_DIR/wikimedia/fundraising/twig.git"
set -x

# git_cache_clone --recursive https://git.wikimedia.org/git/wikimedia/fundraising/crm.git  fundraising-crm
git_cache_clone "$CACHE_DIR/wikimedia/fundraising/crm.git" "$WEB_ROOT"

pushd "$WEB_ROOT"
  git_cache_clone "$CACHE_DIR/wikimedia/fundraising/civicrm.git" civicrm
  git_cache_clone "$CACHE_DIR/wikimedia/fundraising/drupal.git" drupal

  git_cache_clone "$CACHE_DIR/wikimedia/fundraising/DonationInterface.git" DonationInterface
  git_cache_clone "$CACHE_DIR/wikimedia/fundraising/phpmailer.git" phpmailer
  git_cache_clone "$CACHE_DIR/wikimedia/fundraising/twig.git" twig

  ## Reset the .git/config to match remotes in .gitmodules
  git submodule sync

  ## Checkout the proper revisions
  git submodule update

  ## FIXME: Merge into upstream
  patch -p1 < "$SITE_CONFIG_DIR/buildkit-changes.diff"
popd