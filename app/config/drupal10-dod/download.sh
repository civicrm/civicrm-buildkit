#!/bin/bash

## download.sh -- Download Drupal and CiviCRM

###############################################################################

git_cache_setup "https://git.drupalcode.org/project/drupal.git" "$CACHE_DIR/drupal/drupal.git"

#[ -z "$CMS_VERSION" ] && CMS_VERSION=8.7.x
[ -z "$CMS_VERSION" ] && CMS_VERSION='10.0.x'

mkdir "$WEB_ROOT"
git clone "$CACHE_DIR/drupal/drupal.git" -b "$CMS_VERSION" "$WEB_ROOT/web"

pushd "$WEB_ROOT/web" >> /dev/null
  composer_allow_common_plugins
  composer install
  composer require drush/drush
  ## We'll run Civi's standalone phpunit (PHAR)
  if composer info | grep -q ^phpunit/phpunit\ ; then
    composer config "discard-changes" true ## Weird. phpcs has changes which interfere with other work.
    composer remove --dev phpspec/prophecy-phpunit phpunit/phpunit
    composer install --no-dev --no-interaction
  fi
  # drupal8_po_download "${CIVICRM_LOCALES:-de_DE}" "drupal-$( _drupalx_version x.y ).x" devel-5.1.x
  civicrm_download_composer_d8
popd >> /dev/null
