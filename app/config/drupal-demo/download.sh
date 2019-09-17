#!/bin/bash

## download.sh -- Download Drupal and CiviCRM

###############################################################################

[ -z "$CMS_VERSION" ] && CMS_VERSION=7.x
[ -z "$VOL_VERSION" ] && VOL_VERSION='master'
[ -z "$NG_PRFL_VERSION" ] && NG_PRFL_VERSION='master'
[ -z "$RULES_VERSION" ] && RULES_VERSION='master'
[ -z "$DISC_VERSION" ] && DISC_VERSION='master'

mkdir "$WEB_ROOT"
drush8 -y dl drupal-${CMS_VERSION} --destination="$WEB_ROOT" --drupal-project-rename
mv "$WEB_ROOT/drupal" "$WEB_ROOT/web"

pushd "$WEB_ROOT/web"
  drush8 dl -y libraries-1 redirect-1 webform-4 options_element-1 webform_civicrm-4 views-3 login_destination-1 userprotect-1 devel-1 civicrm_error-2.x-dev

  pushd sites/all/modules
    git clone "${CACHE_DIR}/civicrm/civicrm-core.git"                        -b "$CIVI_VERSION"      civicrm
    git clone "${CACHE_DIR}/civicrm/civicrm-drupal.git"                      -b "7.x-$CIVI_VERSION"  civicrm/drupal
    git clone "${CACHE_DIR}/civicrm/civicrm-packages.git"                    -b "$CIVI_VERSION"      civicrm/packages
    case "$CIVI_VERSION" in
     5.17|5.18)
      git clone "${CACHE_DIR}/civicrm/api4.git"                                -b "4.5.2"             civicrm/ext/api4
      ;;
     *)
      EXTCIVIVER=$( php -r '$x=simplexml_load_file("civicrm/xml/version.xml"); echo $x->version_no;' )
      cv dl -b "@https://civicrm.org/extdir/ver=$EXTCIVIVER|cms=Drupal|status=|ready=/org.civicrm.api4.xml" --to="$WEB_ROOT/web/sites/all/modules/civicrm/ext/api4" --dev
     esac

    git clone "${CACHE_DIR}/eileenmcnaughton/civicrm_developer.git"          -b master               civicrm_developer
    git clone "${CACHE_DIR}/civicrm/civivolunteer.git"                       -b "$VOL_VERSION"       civicrm/tools/extensions/civivolunteer
    git clone "${CACHE_DIR}/ginkgostreet/org.civicrm.angularprofiles.git"    -b "$NG_PRFL_VERSION"   civicrm/tools/extensions/org.civicrm.angularprofiles
    git clone "${CACHE_DIR}/civicrm/org.civicoop.civirules.git"              -b "$RULES_VERSION"     civicrm/tools/extensions/org.civicoop.civirules
    git clone "${CACHE_DIR}/TechToThePeople/civisualize.git"                 -b "master"             civicrm/tools/extensions/civisualize
    git clone "${CACHE_DIR}/dlobo/org.civicrm.module.cividiscount.git"       -b "$DISC_VERSION"      civicrm/tools/extensions/cividiscount

    extract-url --cache-ttl 172800 civicrm=http://download.civicrm.org/civicrm-l10n-core/archives/civicrm-l10n-daily.tar.gz
    ## or https://raw.github.com/civicrm/l10n/master/po/fr_CA/civicrm.mo => civicrm/l10n/fr_CA/LC_MESSAGES/
  popd

popd
