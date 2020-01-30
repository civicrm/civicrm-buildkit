#!/bin/bash

## download.sh -- Download Drupal and CiviCRM

###############################################################################

#[ -z "$CMS_VERSION" ] && CMS_VERSION=8.7.x
[ -z "$CMS_VERSION" ] && CMS_VERSION=8
CIVI_VERSION_COMP=$(civicrm_composer_ver "$CIVI_VERSION")

mkdir "$WEB_ROOT"
drush8 -y dl drupal-${CMS_VERSION} --destination="$WEB_ROOT" --drupal-project-rename
mv "$WEB_ROOT/drupal" "$WEB_ROOT/web"

pushd "$WEB_ROOT/web" >> /dev/null
  drush8 dl -y devel-1 libraries userprotect

  #### Ideally...
  ## composer require civicrm/civicrm-asset-plugin:'~1.0.0' civicrm/civicrm-{core,packages,drupal-8}:"$CIVI_VERSION_COMP" --prefer-source
  #### But actually...

  EXTRA_COMPOSER=()
  EXTRA_PATCH=()
  case "$CIVI_VERSION" in
    5.21*) EXTRA_COMPOSER+=( "civicrm/civicrm-setup:0.4.1 as 0.2.99" ) ; EXTRA_PATCH+=( "https://github.com/civicrm/civicrm-core/pull/16328" 'https://github.com/civicrm/civicrm-drupal-8/pull/36' ); ;;
    5.22*) EXTRA_COMPOSER+=( "civicrm/civicrm-setup:0.4.1 as 0.2.99" ) ; EXTRA_PATCH+=( "https://github.com/civicrm/civicrm-core/pull/16413" 'https://github.com/civicrm/civicrm-drupal-8/pull/36'); ;;
    5.23*) EXTRA_COMPOSER+=( "civicrm/civicrm-setup:0.4.1"           ) ; EXTRA_PATCH+=( 'https://github.com/civicrm/civicrm-drupal-8/pull/37' ) ; ;;
    master) EXTRA_COMPOSER+=( "civicrm/civicrm-setup:0.4.1"          ) ; EXTRA_PATCH+=( 'https://github.com/civicrm/civicrm-drupal-8/pull/37' ) ; ;;
    *) cvutil_fatal "This build type is temporarily limited to branches which have a corresponding patchset." ; ;;
  esac
  EXTRA_COMPOSER+=( 'cache/integration-tests:dev-master#b97328797ab199f0ac933e39842a86ab732f21f9' )

  composer require civicrm/civicrm-asset-plugin:'~1.0.0' "${EXTRA_COMPOSER[@]}" civicrm/civicrm-{core,packages,drupal-8}:"$CIVI_VERSION_COMP" --prefer-source
  [ -n "$EXTRA_PATCH" ] && git scan am -N "${EXTRA_PATCH[@]}"
  extract-url --cache-ttl 172800 vendor/civicrm/civicrm-core=http://download.civicrm.org/civicrm-l10n-core/archives/civicrm-l10n-daily.tar.gz ## Issue: Don't write directly into vendor tree
popd >> /dev/null
