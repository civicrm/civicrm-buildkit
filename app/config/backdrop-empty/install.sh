#!/bin/bash

## install.sh -- Create config files and databases; fill the databases

## Transition: Old builds don't have "web/" folder. New builds do.
## TODO: Simplify sometime after Dec 2019
[ -d "$WEB_ROOT/web" ] && CMS_ROOT="$WEB_ROOT/web"

###############################################################################
## Create virtual-host and databases

amp_install

###############################################################################
## Setup Backdrop (config files, database tables)

backdrop_install

###############################################################################
## Extra configuration

pushd "$CMS_ROOT" >> /dev/null
  backdrop_user "$DEMO_USER" "$DEMO_EMAIL" "$DEMO_PASS"
  backdrop_po_import
popd >> /dev/null
