#!/bin/bash

## download.sh -- Download WordPress

###############################################################################
[ -z "$CMS_VERSION" ] && CMS_VERSION=latest

echo "[[Download WordPress]]"
mkdir "$WEB_ROOT" "$WEB_ROOT/web"
pushd "$WEB_ROOT/web" >> /dev/null
  "$PRJDIR/bin/wp" core download --version=$CMS_VERSION
  if [ ! -e "wp-cli.yml" ]; then
    cp -a "$SITE_CONFIG_DIR/wp-cli.yml" "wp-cli.yml"
  fi
popd >> /dev/null
