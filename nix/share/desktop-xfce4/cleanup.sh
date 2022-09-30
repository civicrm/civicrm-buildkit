#!/bin/bash

## Delete various caches that we don't want in the image.
## Note: There are some caches that we do want in the image!

function msg() {
  echo
  echo "# $@"
  echo
}

function prompt_delete() {
  if [ -e "$1" ]; then
    msg "Found $1:"
    ls "$1"
    local CONFIRM
    read -p "# Delete $1 (Y/n)? " CONFIRM
    if [ -z "$CONFIRM" -o "$CONFIRM" = "y" ]; then
      rm -rf "$1"
    fi
  fi
}

nix-collect-garbage
sudo apt-get clean

prompt_delete "$HOME/.cache/mozilla/firefox"
prompt_delete "$HOME/.ssh"

for bld in dmaster wpmaster drupal{,9}-{clean,demo} ; do
  prompt_delete "$HOME/buildkit/build/${bld}"
  prompt_delete "$HOME/buildkit/build/${bld}.sh"
  prompt_delete "$HOME/buildkit/build/.civibuild/snapshot/${bld}"
done
