#!/usr/bin/env bash

## download.sh -- Download Prevem

###############################################################################

echo "[[Download prevem]]"

git_cache_setup "https://github.com/prevem/prevem.git"              "$CACHE_DIR/prevem/prevem.git"

mkdir "$WEB_ROOT"
pushd "$WEB_ROOT" >> /dev/null
  git clone  "$CACHE_DIR/prevem/prevem.git" .
  composer install --no-scripts
popd >> /dev/null
