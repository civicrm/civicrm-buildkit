#!/usr/bin/env bash

## download.sh -- Download Joomla and CiviCRM

###############################################################################

CMS_VERSION=${CMS_VERSION:-latest}

## Joomla has strong expectation of writeable web-root -- eg can't run Civi installer otherwise. :(
amp datadir "$WEB_ROOT" "$WEB_ROOT/web"

pushd "$WEB_ROOT/web" >> /dev/null

if [ "$CMS_VERSION" = 'latest' ]; then
  http_download "https://update.joomla.org/core/j5/default.xml" j5.xml
  # slightly brittle as <version> could include mutliple lines ... but it doesn't now
  CMS_VERSION=$(grep '<version>' j5.xml | sed -E -e 's/<\/?version>//g'  -e 's/\s*//g')
  rm j5.xml
fi

VERSION_DASHES=$(echo $CMS_VERSION | tr '.' '-')
http_download "https://downloads.joomla.org/cms/joomla5/$VERSION_DASHES/Joomla_$VERSION_DASHES-Stable-Full_Package.zip" joomla.zip

unzip -q joomla.zip
rm joomla.zip

# Save a copy of the installation directory for re-installation
zip -q -r installation.zip installation

popd >> /dev/null
