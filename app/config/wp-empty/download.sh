#!/bin/bash

## download.sh -- Download WordPress

###############################################################################
[ -z "$VOL_VERSION" ] && VOL_VERSION='4.4-1.x'

WPCLI_ARGS=
[ -n "$CMS_VERSION" ] && WPCLI_ARGS="$WPCLI_ARGS --version=$CMS_VERSION"

echo "[[Download WordPress]]"
mkdir "$WEB_ROOT"
pushd "$WEB_ROOT" >> /dev/null
  "$PRJDIR/bin/wp" core download$WPCLI_ARGS
  if [ ! -e "wp-cli.yml" ]; then
    ln -s "$SITE_CONFIG_DIR/wp-cli.yml" "wp-cli.yml"
  fi
popd >> /dev/null
