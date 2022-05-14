#!/bin/bash

## download.sh -- Download Joomla and CiviCRM

###############################################################################

CMS_VERSION=${CMS_VERSION:-3.10.9}
CMS_ROOT="$WEB_ROOT/web"

joomla_download
http_cache_setup "https://download.civicrm.org/latest/civicrm-NIGHTLY-joomla.zip" "${CACHE_DIR}/civicrm-NIGHTLY-joomla.zip" 1440
