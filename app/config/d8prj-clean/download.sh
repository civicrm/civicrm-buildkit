#!/bin/bash

## download.sh -- Download Drupal and CiviCRM

###############################################################################

#[ -z "$CMS_VERSION" ] && CMS_VERSION=8.7.x
[ -z "$CMS_VERSION" ] && CMS_VERSION=8.x-dev

composer create-project drupal-composer/drupal-project:"$CMS_VERSION" "$WEB_ROOT" --no-interaction

pushd "$WEB_ROOT" >> /dev/null
  composer require drupal/{devel,libraries,userprotect}
  composer require civicrm/civicrm-asset-plugin:'~1.0.0' civicrm/civicrm-setup:'dev-master as 0.2.99' civicrm/civicrm-{core,packages,drupal-8}:$(civicrm_composer_ver "$CIVI_VERSION") pear/pear_exception:'1.0.1 as 1.0.0' --prefer-source

  ## FIXME: All of the following should be removed/replaced as things get cleaner.
  composer require "cache/integration-tests:dev-master#b97328797ab199f0ac933e39842a86ab732f21f9" ## Issue: it's a require-dev in civicrm-core for E2E/Cache/*; how do we pull in civi require-dev without all other require-dev?
  case "$CIVI_VERSION" in
    5.21*) git scan -N am https://github.com/civicrm/civicrm-core/pull/16328 ; ;; ## Issue: Patches needed in 5.21
    5.22*) git scan -N am https://github.com/civicrm/civicrm-core/pull/16413 ; ;; ## Issue: Patches needed in 5.22 have one trivial difference
    master) git scan -N am https://github.com/civicrm/civicrm-core/pull/{16403,16405,16406,16407,16408,16409} ; ;; ## Issue: This list may be volatile as PRs are getting reviewed.
    *) cvutil_fatal "This build type is temporarily limited to branch which have a corresponding patchset." ; ;;
  esac
  extract-url --cache-ttl 172800 vendor/civicrm/civicrm-core/l10n=http://download.civicrm.org/civicrm-l10n-core/archives/civicrm-l10n-daily.tar.gz ## Issue: Don't write directly into vendor tree
popd >> /dev/null
