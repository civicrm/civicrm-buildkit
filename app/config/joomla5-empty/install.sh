#!/usr/bin/env bash

## install.sh -- Create config files and databases; fill the databases

## Transition: Old builds don't have "web/" folder. New builds do.
## TODO: Simplify sometime after Dec 2019
[ -d "$WEB_ROOT/web" ] && CMS_ROOT="$WEB_ROOT/web"

###############################################################################
## Create virtual-host and databases

amp_install

###############################################################################
## Setup Joomla (config files, database tables)

joomla_install

pushd "$CMS_ROOT" >> /dev/null
  joomla_cli user:add --name="$DEMO_USER" --username="$DEMO_USER" --password="$DEMO_PASS" --email="$DEMO_EMAIL" --usergroup="Registered,Manager"
popd >>/dev/null
