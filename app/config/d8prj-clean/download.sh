#!/bin/bash

## download.sh -- Download Drupal and CiviCRM

###############################################################################

#[ -z "$CMS_VERSION" ] && CMS_VERSION=8.7.x
[ -z "$CMS_VERSION" ] && CMS_VERSION=8.x-dev
CIVI_VERSION_COMP=$(civicrm_composer_ver "$CIVI_VERSION")

composer create-project drupal-composer/drupal-project:"$CMS_VERSION" "$WEB_ROOT" --no-interaction

pushd "$WEB_ROOT" >> /dev/null
  composer require drupal/{devel,libraries,userprotect}

  #### Ideally...
  ## composer require civicrm/civicrm-asset-plugin:'~1.0.0' civicrm/civicrm-{core,packages,drupal-8}:"$CIVI_VERSION_COMP" --prefer-source
  #### But actually...

  EXTRA_COMPOSER=()
  EXTRA_PATCH=()
  case "$CIVI_VERSION" in
    5.21*) EXTRA_COMPOSER+=( "civicrm/civicrm-setup:0.4.0 as 0.2.99" ) ; EXTRA_PATCH+=( "https://github.com/civicrm/civicrm-core/pull/16328" ); ;;
    5.22*) EXTRA_COMPOSER+=( "civicrm/civicrm-setup:0.4.0 as 0.2.99" ) ; EXTRA_PATCH+=( "https://github.com/civicrm/civicrm-core/pull/16413" ); ;;
    5.23*) echo "ok" ; ;;
    master) echo "ok" ; ;;
    *) cvutil_fatal "This build type is temporarily limited to branches which have a corresponding patchset." ; ;;
  esac
  EXTRA_COMPOSER+=( 'cache/integration-tests:dev-master#b97328797ab199f0ac933e39842a86ab732f21f9' )
  EXTRA_COMPOSER+=( 'pear/pear_exception:1.0.1 as 1.0.0') ## weird conflict in drupal-project

  composer require civicrm/civicrm-asset-plugin:'~1.0.0' "${EXTRA_COMPOSER[@]}" civicrm/civicrm-{core,packages,drupal-8}:"$CIVI_VERSION_COMP" --prefer-source
  [ -n "$EXTRA_PATCH" ] && git scan am -N "${EXTRA_PATCH[@]}"
  extract-url --cache-ttl 172800 vendor/civicrm/civicrm-core=http://download.civicrm.org/civicrm-l10n-core/archives/civicrm-l10n-daily.tar.gz ## Issue: Don't write directly into vendor tree
popd >> /dev/null
