#!/bin/bash

## download.sh -- Download Drupal and CiviCRM

###############################################################################

#[ -z "$CMS_VERSION" ] && CMS_VERSION=8.7.x
[ -z "$CMS_VERSION" ] && CMS_VERSION=9.0.x-dev
[ -z "$VOL_VERSION" ] && VOL_VERSION='master'
[ -z "$NG_PRFL_VERSION" ] && NG_PRFL_VERSION='master'
[ -z "$RULES_VERSION" ] && RULES_VERSION='master'
[ -z "$DISC_VERSION" ] && DISC_VERSION='master'

mkdir "$WEB_ROOT"
composer create-project drupal/recommended-project:"$CMS_VERSION" "$WEB_ROOT" --no-interaction

pushd "$WEB_ROOT" >> /dev/null
  composer require drupal/userprotect
  composer require drupal/devel
  ## Some D8 builds include a specific revision of phpunit, but Civi uses standalone phpunit (PHAR)
  if composer info | grep -q ^phpunit/phpunit\ ; then
    composer config "discard-changes" true ## Weird. phpcs has changes which interfere with other work.
    composer remove --dev drupal/core-dev
    composer remove phpunit/phpunit
    composer install --no-dev --no-interaction
  fi
  civicrm_download_composer_d8
  git clone "${CACHE_DIR}/civicrm/civivolunteer.git"                       -b "$VOL_VERSION"       vendor/civicrm/civicrm-core/tools/extensions/civivolunteer
  git clone "${CACHE_DIR}/ginkgostreet/org.civicrm.angularprofiles.git"    -b "$NG_PRFL_VERSION"   vendor/civicrm/civicrm-core/tools/extensions/org.civicrm.angularprofiles
  git clone "${CACHE_DIR}/civicrm/org.civicoop.civirules.git"              -b "$RULES_VERSION"     vendor/civicrm/civicrm-core/tools/extensions/org.civicoop.civirules
  git clone "${CACHE_DIR}/TechToThePeople/civisualize.git"                 -b "master"             vendor/civicrm/civicrm-core/tools/extensions/civisualize
  git clone "${CACHE_DIR}/civicrm/org.civicrm.module.cividiscount.git"     -b "$DISC_VERSION"      vendor/civicrm/civicrm-core/tools/extensions/cividiscount
  git clone "${CACHE_DIR}/civicrm/org.civicrm.contactlayout.git"           -b "master"             vendor/civicrm/civicrm-core/tools/extensions/org.civicrm.contactlayout
popd >> /dev/null
