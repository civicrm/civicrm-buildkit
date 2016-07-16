#!/bin/bash

## download.sh -- Download Joomla and CiviCRM

###############################################################################

CMS_VERSION=${CMS_VERSION:-latest}

joomla site:download . --release="$CMS_VERSION" --www="$WEB_ROOT"

#pushd "$WEB_ROOT" >> /dev/null
#popd >> /dev/null
