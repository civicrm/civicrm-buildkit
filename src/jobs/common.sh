#!/usr/bin/env bash

## Common utilities to include in jobs...

## usage: fatal <error-message>
function fatal() {
  echo "$@" 1>&2
  exit 2
}

## usage: assert_regex <grep-style-regex> <value> [<error-message>]
function assert_regex() {
  local regex="$1"
  local value="$2"
  local error="$3"
  if ! echo "$value" | grep -q "$regex" > /dev/null ; then
    if [ -z "$error" ]; then
      fatal "Error: Value ($value) does not match regex ($regex)"
    else
      fatal "$error"
    fi
  fi
}


## Check that common Jenkins variables are set
function assert_jenkins() {
  assert_regex '^[0-9]\+$' "$EXECUTOR_NUMBER" "EXECUTOR_NUMBER must be a number. (If you are running manually, consider using --mock.)"
  if [ -z "$WORKSPACE" -o ! -d "$WORKSPACE" ]; then
    fatal "WORKSPACE must be a valid path. (If you are running manually, consider using --mock.)"
  fi
}

## Load the BKPROF into the current shell
function use_bknix() {
  if [ ! -z `which await-bknix` ]; then
    await-bknix "$USER" "$BKPROF"
  fi

  case "$BKPROF" in old|min|max|dfl|edge) eval $(use-bknix "$BKPROF") ;; esac

  if [ -z "$BKITBLD" ]; then
    fatal "Failed to find BKITBLD for $BKPROF"
  fi
}

function use_bknix_tmp() {
  use_bknix
  if [ -f /etc/bknix-ci/worker-n ]; then
    (cd "$LOCO_PRJ" && loco clean)
    (cd "$LOCO_PRJ" && loco start)
    trap "cd \"$LOCO_PRJ\" && loco stop" EXIT
  fi
  ## else: This must be a traditional system that runs with system-services.
}
