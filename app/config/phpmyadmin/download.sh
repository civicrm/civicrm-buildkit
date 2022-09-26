#!/bin/bash

## download.sh -- Download Drupal and CiviCRM

###############################################################################

[ -z "$CMS_VERSION" ] && CMS_VERSION=5.2.0

mkdir "$WEB_ROOT"
pushd "$WEB_ROOT"

  extract-url --cache-ttl 172800 dl="https://files.phpmyadmin.net/phpMyAdmin/$CMS_VERSION/phpMyAdmin-$CMS_VERSION-all-languages.zip"
  mv "dl/phpMyAdmin-$CMS_VERSION-all-languages" web

popd
