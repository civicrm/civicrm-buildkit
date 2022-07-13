#!/bin/bash

## download.sh -- Download Drupal and CiviCRM
##
## web/                 Logical web-root, as used by HTTPD. Symlink to real webroot.
## real/                Concrete copy of Drupal (core)
##   sites/
##     all/
##       modules/
##         civicrm/     Concrete copy of Civi (core)
##           drupal/    Concrete copy of Civi-Drupal integration
##           packages/  Concrete copy of Civi packages

###############################################################################

[ -z "$CMS_VERSION" ] && CMS_VERSION=7


drupal_download

pushd "$WEB_ROOT/web"
  pushd sites/all/modules
    git clone "${CACHE_DIR}/civicrm/civicrm-core.git"                        -b "$CIVI_VERSION"      civicrm
    git clone "${CACHE_DIR}/civicrm/civicrm-drupal.git"                      -b "7.x-$CIVI_VERSION"  civicrm/drupal
    git clone "${CACHE_DIR}/civicrm/civicrm-packages.git"                    -b "$CIVI_VERSION"      civicrm/packages
    git clone "${CACHE_DIR}/civicrm/org.civicoop.civirules.git"              -b master               civicrm/ext/civirules

    extract-url --cache-ttl 172800 civicrm=http://download.civicrm.org/civicrm-l10n-core/archives/civicrm-l10n-daily.tar.gz
    ## or https://raw.github.com/civicrm/l10n/master/po/fr_CA/civicrm.mo => civicrm/l10n/fr_CA/LC_MESSAGES/
  popd
popd

mv "$WEB_ROOT/web" "$WEB_ROOT/real"
ln -sf "$WEB_ROOT/real" "$WEB_ROOT/web"
