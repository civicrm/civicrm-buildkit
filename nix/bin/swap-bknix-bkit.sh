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
  if [ -e "$1" -a -e "$2" ]; then
    fatal "ERROR: $2 already exists."
  elif [ ! -e "$1" -a ! -e "$2" ]; then
    echo "SKIP: $1 and $2 do not exist."
  elif [ ! -e "$1" -a -e "$2" ]; then
    fatal "SKIP: $1 does not exist. $2 already exists."
  else
    mv "$1" "$2"
  fi
}

###############################
## Main

if [ -z "$1" -o -z "$2" ]; then
  echo "usage: $0 <mode> <bknix-base-dir>"
  echo "ex: $0 ci ~/bknix"
  echo
  echo "<mode> is either \"ci\" or \"developer\""
  exit 2
else
  MODE="$1"
  TGT=$(echo $2 | sed 's:/*$::')
fi


case "$MODE" in
  developer)
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
    ## tmp data is part of build/.civibuild

    ## Swap top level folders
    safe_rename "$BKNIX_ORIG"                     "$BKNIX_BAK"
    safe_rename "$BKNIX_BAK/civicrm-buildkit"     "$BKIT_FINAL"

    ;;

  ci)
    PROFILE=$(echo $(basename $TGT) | cut -f2 -d- )
    BKNIX_ORIG=$TGT
    BKNIX_BAK=$TGT.bak
    BKIT_ORIG=$TGT/civicrm-buildkit
    BKIT_FINAL=$TGT
    AMP_ORIG=$BKNIX_ORIG/var/amp
    AMP_FINAL=$HOME/_bknix/amp/$PROFILE
    TMP_FINAL=$TGT.tmp

    mkdir -p "$HOME/_bknix/amp"

    ## Migrate data folders
    safe_rename "$BKNIX_ORIG/build"               "$BKIT_ORIG/build"
    mkdir -p    "$BKIT_ORIG/build/.civibuild"
    safe_rename "$BKIT_ORIG/app/tmp/git-cache"    "$BKIT_ORIG/build/.civibuild/cache"
    safe_rename "$BKIT_ORIG/app/snapshot"         "$BKIT_ORIG/build/.civibuild/snapshot"
    safe_rename "$AMP_ORIG"                       "$AMP_FINAL"
    safe_rename "$BKIT_ORIG/app/tmp"              "$TMP_FINAL"

    ## Swap top level folders
    safe_rename "$BKNIX_ORIG"                     "$BKNIX_BAK"
    safe_rename "$BKNIX_BAK/civicrm-buildkit"     "$BKIT_FINAL"

    ;;

  *)
    fatal "Unrecognized mode: $MODE"
    ;;
esac

