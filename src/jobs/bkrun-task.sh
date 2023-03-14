#!/usr/bin/env bash

## This is a bkrun task which forwards the active Jenkins job (from user "dispatcher" to user "runner-N").
##
## This script is part of a 4-step lifecycle:
##
## 1. REQUEST: The `dispatcher` receives a Jenkins job. It records the current request.
## 2. SETUP: The user `runner-N` should have a re-usable/baseline environment with
##    common tools and caches. Initialize these.
## 3. EXEC:  The user `runner-N` should fetch and execute the specific code-under-test.
## 4. ARTIFACTS: The user `runner-N` should output any interesting artifacts,
##    such as JUnit XML files or compiled binaries.
##
## Each step is described below with examples.

#####################################################################
## Internal Environment
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
## TASK: New Request
## USER: "dispatcher"
## EXAMPLE: `bkrun-task.sh request > /tmp/request-1234.txt`

## Generate a request message. This will be relayed to other subtasks.
## Execute as "dispatcher".
function do_request() {
  echo >&2 "[$USER] Generate request (with CIVIVER=$CIVIVER WORKSPACE=$WORKSPACE)"
  env | known_variables
}

#####################################################################
## TASK: Setup Base Layer
## USER: "runner-N"
## HOME FILE MODE: "Base"
## EXAMPLE: `bkrun-task.sh setup /tmp/request-1234.txt > /tmp/my-log.txt`

## Use this to download common tools or warm-up common caches. Anything you
## do during "setup" will may be re-used in future calls.

## Do not use this for the heavy-lifting of job execution. You probably
## should NOT retrieve any unapproved/PR content.

function do_setup() {
  load_request "$request"
  echo >&2 "[$USER] Run setup for request $request (with CIVIVER=$CIVIVER WORKSPACE=$WORKSPACE)"

  git config --global user.email "$USER@example.com"
  git config --global user.name "$USER"

  if [ ! -d "$HOME/buildkit" ]; then
    git clone https://github.com/civicrm/civicrm-buildkit/ "$HOME/buildkit"
  else
    (cd "$HOME/buildkit" && git pull)
  fi

  # (cd "$HOME/buildkit" && nix-shell -A min --run './bin/civi-download-tools')
  (cd "$HOME/buildkit" && nix-shell -A min --run './bin/civi-download-tools && civibuild cache-warmup')
  ## Note: this means that we download the toolchain in 'min' and re-use it for min/dfl/max/whatever.

  # echo "EXEC: Start pre-setup shell. Press Ctrl-D to finish pre-run shell." && bash
}

#####################################################################
## TASK: Execute job
## USER: "runner-N"
## HOME FILE MODE: "Temp"
## EXAMPLE: `bkrun-task.sh exec /tmp/request-1234.txt > /tmp/my-log.txt`

## Use this to do the heavy-lifting of job execution. You might create
## new sites, run PHPUnit, etc.

## You will be allowed to write files anywhere in "$HOME", but they will be
## reset when the job finishes.

function do_exec() {
  load_request "$request"
  echo >&2 "[$USER] Run exec for request $request (with CIVIVER=$CIVIVER WORKSPACE=$WORKSPACE)"

  # echo "EXEC: Start pre-run shell. Press Ctrl-D to finish pre-run shell." && bash

  use_workspace
  mkdir build
  cd build
  cat "$request" > env-requested.txt
  cat "$request" | well_formed_variables | known_variables | switch_home > env-effective.txt

  cd "$HOME/buildkit"
  cat ".loco/worker-n.yml" | grep -v CIVI_TEST_MODE > ".loco/loco.yml"
  local cmd=$(printf "run-bknix-job --loaded %q" "$BKPROF")
  nix-shell -A "$BKPROF" --run "$cmd"

  # echo "EXEC: Start post-run shell. Press Ctrl-D to finish post-run shell." && nix-shell -A "$BKPROF"
}

#####################################################################
## TASK: Export artifacts
## USER: "runner-N"
## HOME FILE MODE: "Temp"
## EXAMPLE: `bkrun-task.sh artifacts /tmp/request-1234.txt > /tmp/results.tar`

## After executing the job, find any interesting artifacts and return them.
## These files will be placed in the "dispatcher"s workspace. This task is
## called even if the overall job fails. (For example, when testing
## `phpunit-core-exts`, there may be 5 PHPUnit suites. We should report the
## `*.xml` results for suites 1,2,3,4 even if suite 5 crasahed.)

## Take care the STDOUT should be a "tar" file. Send any messages to STDERR.

function do_artifacts() {
  load_request "$request"
  echo >&2 "[$USER] Send artifacts for $request"

  ## To align with Jenkins convention, anything that we generated in
  ## "$WORKSPACE" will be exported.
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
