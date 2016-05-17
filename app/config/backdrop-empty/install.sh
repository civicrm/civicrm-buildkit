#!/bin/bash

## install.sh -- Create config files and databases; fill the databases

###############################################################################
## Create virtual-host and databases

amp_install

###############################################################################
## Setup Backdrop (config files, database tables)

backdrop_install

###############################################################################
## Extra configuration

