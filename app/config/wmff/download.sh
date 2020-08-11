#!/bin/bash
set +x
git_cache_setup "https://gerrit.wikimedia.org/r/wikimedia/fundraising/crm.git" "$CACHE_DIR/wikimedia/fundraising/crm.git"
set -x

git clone --recursive "$CACHE_DIR/wikimedia/fundraising/crm.git" "$WEB_ROOT"

pushd "$WEB_ROOT"
  ## Reset the .git/config to match remotes in .gitmodules
  git submodule sync

  ## Checkout the proper revisions
  git submodule update --init --recursive

popd
