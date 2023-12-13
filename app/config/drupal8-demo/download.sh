#!/usr/bin/env bash

## download.sh -- Download Drupal and CiviCRM

###############################################################################

[ -z "$CMS_VERSION" ] && CMS_VERSION=8.9.x-dev
[ -z "$VOL_VERSION" ] && VOL_VERSION='master'
[ -z "$NG_PRFL_VERSION" ] && NG_PRFL_VERSION='master'
[ -z "$RULES_VERSION" ] && RULES_VERSION='master'
[ -z "$DISC_VERSION" ] && DISC_VERSION='master'

mkdir "$WEB_ROOT"
composer create-project drupal/recommended-project:"$CMS_VERSION" "$WEB_ROOT" --no-interaction --no-install

pushd "$WEB_ROOT" >> /dev/null
  composer_allow_common_plugins
  composer install
  composer require drupal/userprotect
  ## Some D8 builds include a specific revision of phpunit, but Civi uses standalone phpunit (PHAR)
  if composer info | grep -q ^phpunit/phpunit\ ; then
    composer config "discard-changes" true ## Weird. phpcs has changes which interfere with other work.
    composer remove --dev drupal/core-dev
    composer remove phpunit/phpunit
    composer install --no-dev --no-interaction
  fi
  civicrm_download_composer_d8
  git_cache_clone "civicrm/org.civicoop.civirules"                      -b "$RULES_VERSION"     vendor/civicrm/civicrm-core/tools/extensions/org.civicoop.civirules
  git_cache_clone "TechToThePeople/civisualize"                         -b "master"             vendor/civicrm/civicrm-core/tools/extensions/civisualize
  git_cache_clone "civicrm/org.civicrm.module.cividiscount"             -b "$DISC_VERSION"      vendor/civicrm/civicrm-core/tools/extensions/cividiscount
  git_cache_clone "civicrm/org.civicrm.contactlayout"                   -b "master"             vendor/civicrm/civicrm-core/tools/extensions/org.civicrm.contactlayout

popd >> /dev/null
