#!/bin/bash

## download.sh -- Download CiviCRM

###############################################################################

echo "[[Check pre-requisites]]"
if `which mkdocs` >> /dev/null ; then
  echo "Found mkdocs"
else
  echo "Missing mkdocs. Please install it globally (eg /usr/bin or /usr/local/bin). http://www.mkdocs.org/"
  exit 1
fi

echo "[[Download civicrm-docs]]"

git_cache_setup "https://lab.civicrm.org/documentation/docs-publisher.git" "$CACHE_DIR/LAB/documentation/docs-publisher.git"

mkdir "$WEB_ROOT"
pushd "$WEB_ROOT" >> /dev/null
  git clone  "$CACHE_DIR/LAB/documentation/docs-publisher.git" .
  composer install --no-scripts
popd >> /dev/null
