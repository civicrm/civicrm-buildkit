#!/bin/bash

## download.sh -- Download Drupal and CiviCRM

###############################################################################

[ -z "$CMS_VERSION" ] && CMS_VERSION=7.x

[ -d "$WEB_ROOT.drushtmp" ] && rm -rf "$WEB_ROOT.drushtmp"
drush -y dl drupal-${CMS_VERSION} --destination="$WEB_ROOT.drushtmp" --drupal-project-rename
mv "$WEB_ROOT.drushtmp/drupal" "$WEB_ROOT"
[ -d "$WEB_ROOT.drushtmp" ] && rm -rf "$WEB_ROOT.drushtmp"

pushd "$WEB_ROOT"
  drush dl -y libraries-1.0 views-3.7 devel

  pushd sites/all/modules
    git clone "${CACHE_DIR}/civicrm/civicrm-core.git"                        -b "$CIVI_VERSION"      civicrm
    git clone "${CACHE_DIR}/civicrm/civicrm-drupal.git"                      -b "7.x-$CIVI_VERSION"  civicrm/drupal
    git clone "${CACHE_DIR}/civicrm/civicrm-packages.git"                    -b "$CIVI_VERSION"      civicrm/packages
    git clone "${CACHE_DIR}/eileenmcnaughton/civicrm_developer.git"          -b master               civicrm_developer

    extract-url --cache-ttl 172800 civicrm=http://download.civicrm.org/civicrm-l10n-core/archives/civicrm-l10n-daily.tar.gz
    ## or https://raw.github.com/civicrm/l10n/master/po/fr_CA/civicrm.mo => civicrm/l10n/fr_CA/LC_MESSAGES/
  popd

popd
