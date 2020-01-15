#!/bin/bash

## download.sh -- Download Drupal and CiviCRM

###############################################################################

#[ -z "$CMS_VERSION" ] && CMS_VERSION=8.7.x
[ -z "$CMS_VERSION" ] && CMS_VERSION=8

mkdir "$WEB_ROOT"
drush8 -y dl drupal-${CMS_VERSION} --destination="$WEB_ROOT" --drupal-project-rename
mv "$WEB_ROOT/drupal" "$WEB_ROOT/web"

## Some things that aren't published yet
mkdir "$WEB_ROOT/repo"
git clone https://lab.civicrm.org/dev/civicrm-asset-plugin "$WEB_ROOT/repo/civicrm-asset-plugin" -b master-relative
#git clone https://github.com/civicrm/civicrm-setup/ "$WEB_ROOT/repo/civicrm-setup"
git clone https://github.com/totten/civicrm-setup/ "$WEB_ROOT/repo/civicrm-setup" -b master-misc

pushd "$WEB_ROOT/web"
  drush8 dl -y devel-1 libraries userprotect
  ## TODO /civicrm/civicrm-drupal-8.git /civicrm/civicrm-core.git /civicrm/civicrm-packages.git http://download.civicrm.org/civicrm-l10n-core/archives/civicrm-l10n-daily.tar.gz

  composer config repositories.local path "$WEB_ROOT/repo/*"
  sed -i.bak 's;"require-dev": \[\],;;' composer.json  ## WTF

  composer require civicrm/civicrm-asset-plugin:'dev-master-relative' civicrm/civicrm-setup:'dev-master-misc as 0.2.99'
  composer require civicrm/civicrm-{core,packages,drupal-8}:$(civicrm_composer_ver "$CIVI_VERSION") --prefer-source

  ## FIXME: Remove this
  pushd vendor/civicrm/civicrm-core >> /dev/null
    patch -p1 < "$SITE_CONFIG_DIR/classloader-packages.patch"
  popd >> /dev/null

  #composer require roundearth/civicrm-composer-plugin civicrm/civicrm-setup:'dev-master as 0.2.1' civicrm/civicrm-{core,drupal-8}:~${CIVI_VERSION}.0 pear/pear_exception:'1.0.1 as 1.0.0'
popd
