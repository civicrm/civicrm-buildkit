#!/bin/bash
set -e

if [ -e $HOME/.profile ]; then . $HOME/.profile; fi
[ -z `which await-bknix` ] || await-bknix "$USER" "dfl"
case "$BKPROF" in min|max|dfl) eval $(use-bknix "$BKPROF") ;; esac
if [ -z "$BKITBLD" ]; then echo "Invalid BKPROF"; exit 1; fi

civi-test-pr \
  --patch="https://github.com/civicrm/civicrm-core/pull/${ghprbPullId}" \
  --exclude-group ornery $SUITES
exit $?
