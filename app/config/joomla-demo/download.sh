#!/bin/bash

## download.sh -- Download Drupal and CiviCRM

###############################################################################

git_cache_setup "https://github.com/joomla/joomla-cms.git" "$GIT_CACHE_DIR/joomla/joomla-cms.git"
git clone "$GIT_CACHE_DIR/joomla/joomla-cms.git" "$WEB_ROOT"

[ -z "$CMS_VER" ] && CMS_VER=3.2.1
pushd "$WEB_ROOT" >> /dev/null
  git checkout "$CMS_VER"

  ## Submitted PR to include cli/install.php in core -- https://github.com/joomla/joomla-cms/pull/2764
  ## For the moment, we need to add it ourselves
  if [ ! -f "cli/install.php" ]; then
    cp "$SITE_CONFIG_DIR/cli-install.php" "cli/install.php"
  fi

  ## Joomla installer will require deleting the "installation" directory, and that's
  ## going to make for some ucky git statuses.
  # rm -rf .git
popd >> /dev/null
