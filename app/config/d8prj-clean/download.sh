#!/bin/bash

## download.sh -- Download Drupal and CiviCRM

###############################################################################

#[ -z "$CMS_VERSION" ] && CMS_VERSION=8.7.x
[ -z "$CMS_VERSION" ] && CMS_VERSION=8.x-dev

composer create-project drupal-composer/drupal-project:"$CMS_VERSION" "$WEB_ROOT" --no-interaction

## FIXME: Some things that aren't published yet
mkdir "$WEB_ROOT/repo"
git clone https://lab.civicrm.org/dev/civicrm-asset-plugin "$WEB_ROOT/repo/civicrm-asset-plugin" -b master-relative
git clone https://github.com/totten/civicrm-setup/ "$WEB_ROOT/repo/civicrm-setup" -b master-misc

pushd "$WEB_ROOT" >> /dev/null
  composer require drupal/{devel,libraries,userprotect}

  composer config repositories.local path "$WEB_ROOT/repo/*"
  sed -i.bak 's;"require-dev": \[\],;;' composer.json  ## WTF

  composer require civicrm/civicrm-asset-plugin:'dev-master-relative' civicrm/civicrm-setup:'dev-master-misc as 0.2.99'
  composer require civicrm/civicrm-{core,packages,drupal-8}:$(civicrm_composer_ver "$CIVI_VERSION") pear/pear_exception:'1.0.1 as 1.0.0' --prefer-source

  ## Port over patches from totten/5.21-packages. Use cherry-pick to allow multi-version support.
  ## FIXME: Remove this once patches are merged.
  pushd vendor/civicrm/civicrm-core >> /dev/null
    git remote add totten 'https://github.com/totten/civicrm-core.git'
    git fetch totten 5.21-packages
    git checkout -b local-patches
    git cherry-pick $( git log --reverse --format=%h origin/5.21..totten/5.21-packages )
  popd >> /dev/null

  ## TODO http://download.civicrm.org/civicrm-l10n-core/archives/civicrm-l10n-daily.tar.gz
popd >> /dev/null
