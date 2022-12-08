#!/bin/bash
set -e

#### NOTE: The canonical version of this file is 'src/pogo/wrapper.sh'.
#### Other versions are generated copies.

## Determine the absolute path of the directory with the file
## usage: absdirname <file-path>
function absdirname() {
  pushd $(dirname $0) >> /dev/null
    pwd
  popd >> /dev/null
}

SELF=$(basename "$0")
BINDIR=$(absdirname "$0")
PRJDIR=$(dirname "$BINDIR")
[ -z "$CIVIBUILD_HOME" ] && TMPDIR="$PRJDIR/app/tmp" || TMPDIR="$CIVIBUILD_HOME/.civibuild/tmp"

#exec pogo --run-mode=local --dl="$TMPDIR/$SELF-{PHP_XY}" -- "$PRJDIR/src/pogo/$SELF.php" "$@"
exec pogo --run-mode=local --dl="$PRJDIR/extern/$SELF-php{PHP_XY}" -- "$PRJDIR/src/pogo/$SELF.php" "$@"
