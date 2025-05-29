#!/usr/bin/env bash
export POGO_SCRIPT='/Users/totten/bknix/src/pogo/import-rn.php'
export POGO_AUTOLOAD='/Users/totten/bknix/tools/import-rn/vendor/autoload.php'
export POGO_STDIN=
[ -e '/Users/totten/bknix/tools/import-rn/script.php' ] && RUN_SCRIPT='/Users/totten/bknix/tools/import-rn/script.php' || RUN_SCRIPT="$POGO_SCRIPT"
exec php  -d 'auto_prepend_file=/Users/totten/bknix/tools/import-rn/vendor/autoload.php' "$RUN_SCRIPT" "$@"
