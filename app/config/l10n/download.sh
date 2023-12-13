#!/usr/bin/env bash

## download.sh -- Download CiviCRM

###############################################################################

git_cache_setup "https://github.com/civicrm/l10n.git"           "$CACHE_DIR/civicrm/l10n.git"

###############################################################################

echo "[[Download CiviCRM]]"

mkdir "$WEB_ROOT"

git clone ${CACHE_DIR}/civicrm/l10n.git                -b "$CIVI_VERSION"     "$WEB_ROOT/l10n"
git_cache_clone_id civicrm/civicrm-core                -b "$CIVI_VERSION"     "$WEB_ROOT/civicrm-core"
git_cache_clone_id civicrm/civicrm-drupal              -b "7.x-$CIVI_VERSION" "$WEB_ROOT/civicrm-drupal"
git_cache_clone_id civicrm/civicrm-joomla              -b "$CIVI_VERSION"     "$WEB_ROOT/civicrm-joomla"
git_cache_clone_id civicrm/civicrm-wordpress           -b "$CIVI_VERSION"     "$WEB_ROOT/civicrm-wordpress"
git_cache_clone_id civicrm/civicrm-packages            -b "$CIVI_VERSION"     "$WEB_ROOT/civicrm-packages"

mkdir "$WEB_ROOT/web"
