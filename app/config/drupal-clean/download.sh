#!/bin/bash

## download.sh -- Download Drupal and CiviCRM

###############################################################################

[ -z "$CMS_VERSION" ] && CMS_VERSION=7.x

mkdir "$WEB_ROOT"
drush8 -y dl drupal-${CMS_VERSION} --destination="$WEB_ROOT" --drupal-project-rename
mv "$WEB_ROOT/drupal" "$WEB_ROOT/web"

pushd "$WEB_ROOT/web"
  drush dl -y libraries-1.0 views-3.7 devel

  pushd sites/all/modules
    git clone "${CACHE_DIR}/civicrm/civicrm-core.git"                        -b "$CIVI_VERSION"      civicrm
    git clone "${CACHE_DIR}/civicrm/civicrm-drupal.git"                      -b "7.x-$CIVI_VERSION"  civicrm/drupal
    git clone "${CACHE_DIR}/civicrm/civicrm-packages.git"                    -b "$CIVI_VERSION"      civicrm/packages
    git clone "${CACHE_DIR}/eileenmcnaughton/civicrm_developer.git"          -b master               civicrm_developer

    ## The core test suite is currently intertwined with APIv4, so we have to get a copy for `Core-PR` and `Core-Matrix` runs.
    case "$CIVI_VERSION" in
      master)
        git clone "${CACHE_DIR}/civicrm/api4.git"                            -b "master"             civicrm/ext/api4
        ;;
      *)
        EXTCIVIVER=$( php -r '$x=simplexml_load_file("civicrm/xml/version.xml"); echo $x->version_no;' )
        cv dl -b "@https://civicrm.org/extdir/ver=$EXTCIVIVER|cms=Drupal|status=|ready=/org.civicrm.api4.xml" --to="$WEB_ROOT/web/sites/all/modules/civicrm/ext/api4" --dev
        ;;
    esac

    extract-url --cache-ttl 172800 civicrm=http://download.civicrm.org/civicrm-l10n-core/archives/civicrm-l10n-daily.tar.gz
    ## or https://raw.github.com/civicrm/l10n/master/po/fr_CA/civicrm.mo => civicrm/l10n/fr_CA/LC_MESSAGES/
  popd

popd
