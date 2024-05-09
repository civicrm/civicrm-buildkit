#!/bin/bash

## download.sh -- Download Drupal and CiviCRM

###############################################################################

#[ -z "$CMS_VERSION" ] && CMS_VERSION=8.7.x
[ -z "$CMS_VERSION" ] && CMS_VERSION='^10'

mkdir "$WEB_ROOT"
composer create-project drupal/recommended-project:"$CMS_VERSION" "$WEB_ROOT" --no-interaction

pushd "$WEB_ROOT" >> /dev/null
  composer_allow_common_plugins
  composer require drupal/userprotect
  composer require drush/drush
  ## Some D8 builds include a specific revision of phpunit, but Civi uses standalone phpunit (PHAR)
  if composer info | grep -q ^phpunit/phpunit\ ; then
    composer config "discard-changes" true ## Weird. phpcs has changes which interfere with other work.
    composer remove --dev drupal/core-dev
    composer remove phpunit/phpunit
    composer install --no-dev --no-interaction
  fi
  drupal8_po_download "${CIVICRM_LOCALES:-de_DE}" "drupal-$( _drupalx_version x.y ).x"

  git_cache_clone "civicrm/civicrm-core"                                -b "$CIVI_VERSION"      src/civicrm-core
  git_cache_clone "civicrm/civicrm-drupal-8"                            -b "$CIVI_VERSION"      src/civicrm-drupal-8
  git_cache_clone "civicrm/civicrm-packages"                            -b "$CIVI_VERSION"      src/civicrm-packages
  composer config repositories.civicrm-core '{"type": "path", "url": "./src/civicrm-core", "options": { "symlink": false } }'
  composer config repositories.civicrm-drupal-8 '{"type": "path", "url": "./src/civicrm-drupal-8", "options": { "symlink": false }}'
  composer config repositories.civicrm-packages '{"type": "path", "url": "./src/civicrm-packages", "options": { "symlink": false }}'
  ## The symlink:false helps when running the installation step. We should probably fix that...

  civibuild_apply_user_extras
  civicrm_download_composer_d8 vendor/civicrm/civicrm-core
  ## Note: This build has two paths for civicrm (via 'src' and 'vendor'). Give a hint about which is canonical.
popd >> /dev/null
