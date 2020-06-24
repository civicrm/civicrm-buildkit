#!/bin/bash

## The bknix.git is being merged into buildkit.git
## This performs a migration, swapping the bknix.git and buildkit.git folders while preserving the main data.
##
## Before migration:
##   ~/bknix                    This is a copy of 'bknix.git'
##   ~/bknix/civicrm-buildkit   This is a copy of `civicrm-buildkit.git'
##   ~/bknix/build              This is a collection of local builds
##   ~/bknix/.loco/var.keep     This has some metadata about the local buidls
##
## After migration:
##   ~/bknix.bak                This is an old copy of `bknix.git` which is no longer needed.
##   ~/bknix                    This is a copy of `civicrm-buildkit.git'
##   ~/bknix/build              This is a collection of local builds
##   ~/bknix/.loco/var.keep     This has some metadata about the local buidls

###############################
## Utils

function fatal() {
  echo "$@" 1>&2
  exit 1
}

function assert_exists() {
  for F in "$@" ; do
    if [ ! -e "$F" ]; then
      fatal "ERROR: The folder $F should exist. It is missing."
    fi
  done
}

function assert_not_exists() {
  for F in "$@" ; do
    if [ -e "$F" ]; then
      fatal "ERROR: The folder $F should not exist. But there it is."
    fi
  done
}

function safe_rename() {
  ## Normal "mv" is too clever about handling extant/non-extant destinations.
  if [ -e "$2" ]; then
    fatal "ERROR: $2 already exists"
  fi
  mv "$1" "$2"
}

###############################
## Main

if [ -z "$1" ]; then
  echo "usage: $0 <bknix-base-dir>"
  echo "ex: $0 ~/bknix"
  exit 2
else
  TGT=$(echo $1 | sed 's:/*$::')
fi

echo "Migrating $TGT"

BKNIX_ORIG=$TGT
BKNIX_BAK=$TGT.bak
BKIT_ORIG=$TGT/civicrm-buildkit
BKIT_FINAL=$TGT

assert_exists     "$BKNIX_ORIG" "$BKIT_ORIG" "$BKIT_ORIG/nix"
assert_not_exists "$BKNIX_BAK"
assert_exists     "$BKNIX_ORIG/.loco" "$BKIT_ORIG/.loco"
assert_exists     "$BKNIX_ORIG/build" "$BKNIX_ORIG/.loco/var.keep"
assert_not_exists "$BKIT_ORIG/build"  "$BKIT_ORIG/.loco/var.keep"

## Migrate data folders
safe_rename "$BKNIX_ORIG/build"               "$BKIT_ORIG/build"
safe_rename "$BKNIX_ORIG/.loco/var.keep"      "$BKIT_ORIG/.loco/var.keep"

## Swap top level folders
safe_rename "$BKNIX_ORIG"                     "$BKNIX_BAK"
safe_rename "$BKNIX_BAK/civicrm-buildkit"     "$BKIT_FINAL"

