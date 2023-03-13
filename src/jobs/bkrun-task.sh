#!/usr/bin/env bash

## This is a bkrun task which forwards the active Jenkins job (from user "dispatcher" to user "runner-N").

#####################################################################
## Environment
##
## BKNIX_JOBS:   This folder (containing the *.job scripts)
## request:      File with the serialized request

#####################################################################
## Main
function main() {
  case "$1" in
    request)   do_request ; ;;
    setup)     request="$2" ; do_setup ; ;;
    exec)      request="$2" ; do_exec ; ;;
    artifacts) request="$2" ; do_artifacts ; ;;
  esac
}

#####################################################################
## Tasks

## Generate a request message. This will be relayed to other subtasks.
## Execute as "dispatcher".
function do_request() {
  echo >&2 "[$USER] Generate request (with CIVIVER=$CIVIVER WORKSPACE=$WORKSPACE)"
  env | known_variables
}

## Setup the base-layer. This is the section shared across multiple runs.
## Execute as "runner-N".
function do_setup() {
  load_request "$request"
  echo >&2 "[$USER] Run setup for request $request (with CIVIVER=$CIVIVER WORKSPACE=$WORKSPACE)"
}

## Execute this specific task.
## Execute as "runner-N".
function do_exec() {
  load_request "$request"
  echo >&2 "[$USER] Run exec for request $request (with CIVIVER=$CIVIVER WORKSPACE=$WORKSPACE)"

  use_workspace
  mkdir build
  md5sum "$request" > "build/my-checksum"
}

## Output an archive with the artifacts from ths job.
## Execute as "runner-N".
function do_artifacts() {
  load_request "$request"
  echo >&2 "[$USER] Send artifacts for $request"

  use_workspace
  tar c .
}

#####################################################################
## Utilities

## Ensure that the WORKSPACE folder is setup.
function use_workspace() {
  echo >&2 "Use workspace ($WORKSPACE)"
  if [ -z "$WORKSPACE" ]; then
    echo >&2 "Error: Missing WORKSPACE"
    exit 1
  fi
  if [ ! -d "$WORKSPACE" ]; then
    mkdir -p "$WORKSPACE"
  fi
  cd "$WORKSPACE"
}

## Load data from a request file.
## usage: load_request <REQ_FILE>
function load_request() {
  #eval $( cat "$1" | well_formed_variables | new_variables | escape_variables )
  eval $( cat "$1" | well_formed_variables | known_variables | switch_home | escape_variables )
}

function well_formed_variables() {
  grep -v '^#' | grep '^[a-zA-Z0-9_]\+='
}

## Filter the variables. Only return new/undefined values.
##
## STDIN: List of KEY=VALUE pairs (unescaped values)
## STDOUT: List of KEY=VALUE pairs (unescaped values)
function new_variables() {
  while IFS= read -r line; do
    var=$(echo "$line" | cut -d= -f1)
    if [[ -z "${!var}" ]]; then
      echo "$line"
    fi
  done

}

## Filter the variable. Only return well-known (pre-declared) variables.
##
## STDIN: List of KEY=VALUE pairs (unescaped values)
## STDOUT: List of KEY=VALUE pairs (unescaped values)
function known_variables() {
  env_list=" "$(echo $( cat "$BKNIX_JOBS/env.txt" | grep '^[a-zA-Z0-9_]\+$' ; echo ))" "
  #echo >&2 "$JOBDIR/env.txt: $env_list"
  while IFS= read -r line; do
    var=$(echo "$line" | cut -d= -f1)
    if [[ "$env_list" =~ " $var " ]]; then
      echo "$line"
    fi
  done
}

## Filter any variables that refer to `~dispatcher` and plug in our own user.
function switch_home() {
  local old_home=$(echo ~dispatcher)
  sed "s;$old_home;$HOME;"
}


## Encode the variables in a way that's suitable for "eval"
##
## STDIN: List of KEY=VALUE pairs (unescaped values)
## STDOUT: List of KEY=VALUE pairs (escaped values; suited for "eval")
function escape_variables() {
  local my_exports=()

  while IFS= read -r line; do
    var=$(echo "$line" | cut -d= -f1)
    val=$(echo "$line" | cut -d= -f2-)
    printf "$var=%q\n" "$val"
    my_exports+=( "$var" )
  done

  if [ ${#my_exports[@]} -gt 0 ]; then
    echo "export ${my_exports[@]}"
  fi
}

function absdirname() {
  pushd $(dirname $0) >> /dev/null
    pwd
  popd >> /dev/null
}

#####################################################################
## Go

export BKNIX_JOBS=$(absdirname "$0")
main "$@"
