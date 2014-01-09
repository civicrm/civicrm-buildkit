#!/bin/bash

## download.sh -- Download Joomla and CiviCRM

###############################################################################

git_cache_setup "https://github.com/joomla/joomla-cms.git" "$CACHE_DIR/joomla/joomla-cms.git"
git clone "$CACHE_DIR/joomla/joomla-cms.git" "$WEB_ROOT"

[ -z "$CMS_VER" ] && CMS_VER=3.2.1
pushd "$WEB_ROOT" >> /dev/null
  git checkout "$CMS_VER"

  ## Submitted PR to include cli/install.php in core -- https://github.com/joomla/joomla-cms/pull/2764
  ## For the moment, we need to add it ourselves
  if [ ! -f "cli/install.php" ]; then
    cp "$SITE_CONFIG_DIR/cli-install.php" "cli/install.php"
  fi

  ## TODO: Checkout Civi's code...
  #git clone ${CACHE_DIR}/civicrm/civicrm-joomla.git    -b "$CIVI_VERSION" path/to/checkout/to
  #git clone ${CACHE_DIR}/civicrm/civicrm-core.git      -b "$CIVI_VERSION" path/to/checkout/to
  #git clone ${CACHE_DIR}/civicrm/civicrm-packages.git  -b "$CIVI_VERSION" path/to/checkout/to/packages

  #git_set_hooks civicrm-joomla      path/to/checkout/to          "../civicrm/tools/scripts/git"
  #git_set_hooks civicrm-core        path/to/checkout/to          "../tools/scripts/git"
  #git_set_hooks civicrm-packages    path/to/checkout/to/packages "../../tools/scripts/git"

popd >> /dev/null
