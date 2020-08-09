#!/bin/bash

## download.sh -- Download Drupal and CiviCRM

###############################################################################

#[ -z "$CMS_VERSION" ] && CMS_VERSION=8.7.x
[ -z "$CMS_VERSION" ] && CMS_VERSION=9
[ -z "$VOL_VERSION" ] && VOL_VERSION='master'
[ -z "$NG_PRFL_VERSION" ] && NG_PRFL_VERSION='master'
[ -z "$RULES_VERSION" ] && RULES_VERSION='master'
[ -z "$DISC_VERSION" ] && DISC_VERSION='master'

mkdir "$WEB_ROOT"
drush8 -y dl drupal-${CMS_VERSION} --destination="$WEB_ROOT" --drupal-project-rename
mv "$WEB_ROOT/drupal" "$WEB_ROOT/web"

pushd "$WEB_ROOT/web" >> /dev/null
  drush8 dl -y devel userprotect
  composer update psr/log ## Some D8 builds are too specific
  ## Some D8 builds include a specific revision of phpunit, but Civi uses standalone phpunit (PHAR)
  if composer info | grep -q ^phpunit/phpunit\ ; then
    composer config "discard-changes" true ## Weird. phpcs has changes which interfere with other work.
    composer remove phpunit/phpunit
    composer install --no-dev --no-interaction
  fi
  civicrm_download_composer_d8
  git clone "${CACHE_DIR}/civicrm/civivolunteer.git"                       -b "$VOL_VERSION"       vendor/civicrm/civicrm-core/tools/extensions/civivolunteer
  git clone "${CACHE_DIR}/ginkgostreet/org.civicrm.angularprofiles.git"    -b "$NG_PRFL_VERSION"   vendor/civicrm/civicrm-core/tools/extensions/org.civicrm.angularprofiles
  git clone "${CACHE_DIR}/civicrm/org.civicoop.civirules.git"              -b "$RULES_VERSION"     vendor/civicrm/civicrm-core/tools/extensions/org.civicoop.civirules
  git clone "${CACHE_DIR}/TechToThePeople/civisualize.git"                 -b "master"             vendor/civicrm/civicrm-core/tools/extensions/civisualize
  git clone "${CACHE_DIR}/dlobo/org.civicrm.module.cividiscount.git"       -b "$DISC_VERSION"      vendor/civicrm/civicrm-core/tools/extensions/cividiscount
  git clone "${CACHE_DIR}/colemanw/exportui.git"       -b "master"             vendor/civicrm/civicrm-core/tools/extensions/exportui
popd >> /dev/null
