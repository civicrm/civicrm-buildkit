#!/bin/bash

## download.sh -- Download Standalone project and CiviCRM core

###############################################################################

# @todo Requires that we register with packagist?
# mkdir "$WEB_ROOT"
# composer create-project civicrm/civicrm-standalone "$WEB_ROOT" --no-interaction
git clone https://github.com/civicrm/civicrm-standalone "$WEB_ROOT"
# git clone https://github.com/artfulrobot/civicrm-standalone -b artfulrobot-clean-install-paths "$WEB_ROOT"

pushd "$WEB_ROOT"
  amp datadir "./data" "./web/uploads"
  composer install
  composer civicrm:publish
popd
