#!/usr/bin/env bash

## download.sh -- Download Joomla and CiviCRM

###############################################################################

CMS_VERSION=${CMS_VERSION:-latest}

## Joomla has strong expectation of writeable web-root -- eg can't run Civi installer otherwise. :(
amp datadir "$WEB_ROOT" "$WEB_ROOT/web"

joomla4_download "$WEB_ROOT/web"
