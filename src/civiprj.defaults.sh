#!/bin/bash

###############################################################################
## Bootstrap variables (generated automatically based on how app is called)

## The location of the civicrm-project tree
# PRJDIR=

## The location of the civicrm-project binaries
# BINDIR=

###############################################################################
## Common variables

## The name of on-going action (eg "create" or "reset")
ACTION=

## Codename for the build instance
SITE_NAME=

## Codename for the build scripts (default: $SITE_NAME)
SITE_TYPE=

## Location of the build scripts (default: app/config/$SITE_TYPE)
SITE_CONFIG_DIR=

## Root directory where the site's code will be installed
## (default: PRJDIR/build/SITE_NAME)
WEB_ROOT=

###############################################################################
## "create" variables defined by civiprj

## Whether to destroy pre-existing source tree
FORCE_DOWNLOAD=

## Whether to destroy pre-existing DB's
FORCE_INSTALL=

## Default user accounts
ADMIN_EMAIL="admin@example.com"
ADMIN_PASS=
ADMIN_USER="admin"
DEMO_EMAIL="demo@example.com"
DEMO_PASS="demo"
DEMO_USER="demo"

## Printable name of the site (default: $SITE_NAME)
CMS_TITLE=

## The CiviCRM API (default: randomly generated)
CIVI_SITE_KEY=

## The CiviCRM branch/version
CIVI_VERSION=master

###############################################################################
## "create" variables defined by */install.sh

## Public URL of the site
## May be set by user (with --url). If omitted, then */install.sh must set it.
## (suggested: autogenerate via amp)
CMS_URL=

## Path to the base of the CMS
CMS_ROOT=

## DB credentials for CMS
## (suggested: autogenerate via 'amp create -f --root="$WEB_ROOT" --prefix=CMS_ --url="$CMS_URL"')
CMS_DB_DSN=
CMS_DB_HOST=
CMS_DB_NAME=
CMS_DB_PASS=
CMS_DB_PORT=
CMS_DB_USER=

## Path to the civicrm-core tree
CIVI_ROOT=

## DB credentials for Civi
## (suggested: autogenerate via 'amp create -f --root="$CIVI_ROOT" --prefix=CIVI_ --no-url')
CIVI_DB_DSN=
CIVI_DB_HOST=
CIVI_DB_NAME=
CIVI_DB_PASS=
CIVI_DB_PORT=
CIVI_DB_USER=

## Path to the civicrm.settings.php
CIVI_SETTINGS=

## Path to the civicrm files directory
CIVI_FILES=

## Path to the civicrm templates_c cache directory
CIVI_TEMPLATEC=

## Name of the CiviCRM UF (Drupal, Drupal6, Joomla, WordPress)
CIVI_UF=

###############################################################################
## "reset"-related variables

## Path to database dump file (default: PRJDIR/app/backup/SITE_NAME/civi.sql.gz) [non-persistent]
CIVI_SQL=

## True if we should skip loading CIVI_SQL [non-persistent]
CIVI_SQL_SKIP=

## Path to database dump file (default: PRJDIR/app/backup/SITE_NAME/cms.sql.gz) [non-persistent]
CMS_SQL=

## True if we should skip loading CMS_SQL [non-persistent]
CMS_SQL_SKIP=

###############################################################################
## List of variables to save in the site's data file for use in future
## invocations
PERSISTENT_VARS="
  ADMIN_EMAIL ADMIN_PASS ADMIN_USER
  DEMO_EMAIL DEMO_PASS DEMO_USER
  CMS_TITLE CMS_URL CMS_ROOT
  CMS_DB_DSN CMS_DB_USER CMS_DB_PASS CMS_DB_HOST CMS_DB_PORT CMS_DB_NAME
  CIVI_ROOT CIVI_SITE_KEY CIVI_VERSION
  CIVI_DB_DSN CIVI_DB_USER CIVI_DB_PASS CIVI_DB_HOSTCIVI_DB_PORT CIVI_DB_NAME
  CIVI_SETTINGS CIVI_FILES CIVI_TEMPLATEC CIVI_UF
  SITE_TYPE
"
# ignore: runtime options like CIVI_SQL_SKIP and FORCE_DOWNLOAD
# future: FACL_USERS