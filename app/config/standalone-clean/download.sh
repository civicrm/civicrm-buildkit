#!/bin/bash

## download.sh -- Download Standalone project and CiviCRM core

###############################################################################

# @todo Requires that we register with packagist?
# mkdir "$WEB_ROOT"
# composer create-project civicrm/civicrm-standalone "$WEB_ROOT" --no-interaction
git clone https://github.com/civicrm/civicrm-standalone $WEB_ROOT
cd $WEB_ROOT
composer install
