#!/bin/bash

## install.sh -- Create config files and databases; fill the databases

###############################################################################
## Create virtual-host and databases

amp_install

###############################################################################
# cvutil_mkdir "$WEB_ROOT/out" "$WEB_ROOT/out/gen" "$WEB_ROOT/out/tmp" "$WEB_ROOT/out/tar" "$WEB_ROOT/out/config"

echo "[[ Download or update universe ]]"

if ! fetch-universe "$WEB_ROOT" ; then
  echo "WARNING: There were errors in cloning or updating repos\n" 1>&2
fi