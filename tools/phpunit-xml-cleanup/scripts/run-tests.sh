#!/usr/bin/env bash

###############################################################################
## Bootstrap

## Determine the absolute path of the directory with the file
## usage: absdirname <file-path>
function absdirname() {
  pushd $(dirname $0) >> /dev/null
    pwd
  popd >> /dev/null
}

SCRDIR=$(absdirname "$0")
PRJDIR=$(dirname "$BINDIR")
INPUT_DIR="$PRJDIR/examples/input"
EXPECTED_DIR="$PRJDIR/examples/expected"
OUTPUT_DIR="$PRJDIR/examples/actual"
export PATH="$PRJDIR/bin:$PATH"

###############################################################################

set -ex

[ -d "$OUTPUT_DIR" ] && rm -rf "$OUTPUT_DIR"
cp -r "$INPUT_DIR" "$OUTPUT_DIR"
phpunit-xml-cleanup "$OUTPUT_DIR"/*.xml

if diff -ru "$EXPECTED_DIR" "$OUTPUT_DIR" > "$OUTPUT_DIR.diff" ; then
  echo "OK"
else
  colordiff < "$OUTPUT_DIR.diff"
  exit 1
fi
