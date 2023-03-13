#!/usr/bin/env bash

#####################################################################
## Environment
##
## request=/path/to/request/file

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
## This runs as part of the dispatch.
function do_request() {
  echo >&2 "Generate request as $USER (with CIVIVER=$CIVIVER)"
  env
}

## Setup the base-layer. This is the section shared across multiple runs.
## This is isolated within runner-$N.
function do_setup() {
  eval $( filter_request < "$request" )
  echo >&2 "Run setup for $request as $USER"
}

## Execute this specific task.
## This is isolated within runner-$N.
function do_exec() {
  eval $( filter_request < "$request" )
  echo >&2 "Run exec for $request as $USER (with CIVIVER=$CIVIVER)"

  mkdir build
  md5sum "$request" > build/my-checksum
}

## Output an archive with the artifacts from ths job.
## This is isolated within runner-$N.
function do_artifacts() {
  echo >&2 "Send artifacts for $request as $USER: $( ls build )"
  tar c build
}

#####################################################################
## Utilities

## Filter a request, focusing on variables that we're interested in loading.
##
## STDIN: List of all KEY=VALUE pairs. (Unescaped values.)
## STDOUT: List of acceptable KEY=VALUE pairs. (Escaped values.)
function filter_request() {
  local my_exports=()

  while IFS= read -r line; do
    var=$(echo "$line" | cut -d= -f1)
    val=$(echo "$line" | cut -d= -f2-)
    # echo >&2 "line [$line] [$var] [$val]"
    if [[ -z "${!var}" ]]; then
      printf "$var=%q\n" "$val"
      my_exports+=( "$var" )
    fi
  done <<< "$(grep -v '^#' | grep '^[a-zA-Z0-9_]\+=')"

  echo "export ${my_exports[@]}"
}

#####################################################################
## Go
main "$@"
