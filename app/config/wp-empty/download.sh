#!/bin/bash

## download.sh -- Download WordPress

###############################################################################
[ -z "$CMS_VERSION" ] && CMS_VERSION=4.8

echo "[[Download WordPress]]"
mkdir "$WEB_ROOT"
pushd "$WEB_ROOT" >> /dev/null
  "$PRJDIR/bin/wp" core download --version=$CMS_VERSION
  if [ ! -e "wp-cli.yml" ]; then
    cp -a "$SITE_CONFIG_DIR/wp-cli.yml" "wp-cli.yml"
  fi
popd >> /dev/null
