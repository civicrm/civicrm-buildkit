#!/usr/bin/env bash
export POGO_SCRIPT='/Users/totten/bknix/src/pogo/forkify.php'
export POGO_AUTOLOAD='/Users/totten/bknix/tools/forkify/vendor/autoload.php'
export POGO_STDIN=
[ -e '/Users/totten/bknix/tools/forkify/script.php' ] && RUN_SCRIPT='/Users/totten/bknix/tools/forkify/script.php' || RUN_SCRIPT="$POGO_SCRIPT"
exec php  -d 'auto_prepend_file=/Users/totten/bknix/tools/forkify/vendor/autoload.php' "$RUN_SCRIPT" "$@"
