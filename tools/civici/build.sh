#!/usr/bin/env bash

## Determine the absolute path of the directory with the file
## usage: absdirname <file-path>
function absdirname() {
  pushd $(dirname $0) >> /dev/null
    pwd
  popd >> /dev/null
}

PRJDIR=$(absdirname "$0")
set -ex

BOX_VERSION=3.8.4
BOX_URL="https://github.com/humbug/box/releases/download/${BOX_VERSION}/box.phar"
BOX_DIR="$PRJDIR/extern/box-$BOX_VERSION"
BOX_BIN="$BOX_DIR/box"
[ ! -f "$BOX_BIN" ] && ( mkdir -p "$BOX_DIR" ; curl -L "$BOX_URL" -o "$BOX_BIN" )

pushd "$PRJDIR" >> /dev/null
  composer install --prefer-dist --no-progress --no-suggest --no-dev
  php -d phar.read_only=0 "$BOX_BIN" build -v
popd >> /dev/null
