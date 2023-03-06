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

## Assert that a list of common variables are well defined.
##
## usage: assert_common <var1 var2 var3...>
## example: assert_common CIVIVER BLDTYPE
function assert_common() {
  for VAR in "$@" ; do
    case "$VAR" in
      ghprbPullId)
        assert_regex '^[0-9]\+$' "$ghprbPullId" "ghprbPullId must be a number."
        ;;
      BKITBLD)
        if [ -z "$BKITBLD" ]; then
          fatal "Failed to find BKITBLD for $BKPROF"
        fi
        ;;
      BLDTYPE)
        assert_regex '^[0-9a-z\.-]\+$' "$BLDTYPE" "Missing or invalid BLDTYPE"
        ;;
      CIVIVER)
        assert_regex '^[0-9a-z\.-]\+$' "$CIVIVER" "Missing or invalid CIVIVER"
        ;;
      EXECUTOR_NUMBER)
        assert_regex '^[0-9]\+$' "$EXECUTOR_NUMBER" "EXECUTOR_NUMBER must be a number. (If you are running manually, consider using --mock.)"
        ;;
      SUITES)
        assert_regex '^[ 0-9a-z\.-]\+$' "$SUITES" "Missing or invalid SUITES"
        ;;
      TIME_FUNC)
        assert_regex '^[ 0-9a-z:\.-]\+$' "$TIME_FUNC" "Missing or invalid TIME_FUNC"
        ;;
      WORKSPACE)
        if [ -z "$WORKSPACE" -o ! -d "$WORKSPACE" ]; then
          fatal "WORKSPACE must be a valid path. (If you are running manually, consider using --mock.)"
        fi
        ;;
      *)
        fatal "Cannot validate unrecognized variable $VAR"
        ;;
    esac
  done
}

## Load the BKPROF into the current shell
function use_bknix() {
  if [ ! -z `which await-bknix` ]; then
    await-bknix "$USER" "$BKPROF"
  fi

  case "$BKPROF" in old|min|max|dfl|edge) eval $(use-bknix "$BKPROF") ;; esac
  assert_common BKITBLD
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

## Setup the standard build folders within the workspace.
## Output variables: WORKSPACE_BUILD WORKSPACE_HTML WORKSPACE_JUNIT WORKSPACE_LOG WORKSPACE_DIST
function init_std_workspace() {
  WORKSPACE_BUILD="$WORKSPACE/build"
  WORKSPACE_HTML="$WORKSPACE_BUILD/html"
  WORKSPACE_JUNIT="$WORKSPACE_BUILD/junit"
  WORKSPACE_LOG="$WORKSPACE_BUILD/log"
  WORKSPACE_DIST="$WORKSPACE_BUILD/dist"
  WORKSPACE_CHECKSTYLE="$WORKSPACE_BUILD/checkstyle"

  ## WORKSPACE and all the other Jenkins vars are exported. We might as well export these...
  export WORKSPACE_BUILD WORKSPACE_HTML WORKSPACE_JUNIT WORKSPACE_LOG WORKSPACE_DIST WORKSPACE_CHECKSTYLE

  if [ ! -d "$WORKSPACE_BUILD" ]; then
    mkdir "$WORKSPACE_BUILD"
  fi

  for dir in "$WORKSPACE_JUNIT" "$WORKSPACE_HTML" "$WORKSPACE_LOG" "$WORKSPACE_DIST" "$WORKSPACE_CHECKSTYLE" ; do
    if [ -d "$dir" ]; then
      rm -rf "$dir"
    fi
    mkdir "$dir"
  done
}

## Remove old files
## This basically just 'rm -rf', but (semantically) it indicates an entry from the workspace that should no longer be in use.
function clean_legacy_workspace() {
  for FILE in "$@" ; do
    if [ -e "$FILE" ]; then
      rm -rf "$FILE"
    fi
  done
}
