#!/usr/bin/env bash

## download.sh -- Download Drupal and CiviCRM
##
## src/
##    civicrm-core/     Concrete copy of Civi (core)
##    civicrm-drupal/   Concrete copy of Civi-Drupal integration
##    civicrm-packages/ Concrete copy of Civi packages
##    l10n/             Concrete copy of Civi translations
## web/                 Concrete copy of Drupal (core)
##   sites/
##     all/
##       modules/
##         civicrm/     Symlink to Civi core
##           drupal/    Symlink to Civi-Drupal
##           packages/  Symlink to Civi packages
##           l10n/      Symlink to Civi translations

###############################################################################

[ -z "$CMS_VERSION" ] && CMS_VERSION=7

drupal_download

mkdir -p "$WEB_ROOT/src"
pushd "$WEB_ROOT/src"
  git_cache_clone "civicrm/civicrm-core"                                -b "$CIVI_VERSION"      civicrm-core
  git_cache_clone "civicrm/civicrm-drupal"                              -b "7.x-$CIVI_VERSION"  civicrm-drupal-7
  git_cache_clone "civicrm/civicrm-packages"                            -b "$CIVI_VERSION"      civicrm-packages
  git_cache_clone "civicrm/org.civicoop.civirules"                      -b master               civirules

  extract-url --cache-ttl 172800 civicrm-l10n=http://download.civicrm.org/civicrm-l10n-core/archives/civicrm-l10n-daily.tar.gz
  ## or https://raw.github.com/civicrm/l10n/master/po/fr_CA/civicrm.mo => civicrm-l10n/l10n/fr_CA/LC_MESSAGES/
popd

mkdir -p "$WEB_ROOT/web/sites/all/modules"
pushd "$WEB_ROOT/web/sites/all/modules"
  ln -sf "$WEB_ROOT/src/civicrm-core"      civicrm
  ln -sf "$WEB_ROOT/src/civicrm-drupal-7"  civicrm/drupal
  ln -sf "$WEB_ROOT/src/civicrm-packages"  civicrm/packages
  ln -sf "$WEB_ROOT/src/civicrm-l10n/l10n" civicrm/l10n
  ln -sf "$WEB_ROOT/src/civirules"         civicrm/ext/civirules
popd
