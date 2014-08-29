#!/bin/bash

###############################################################################
## Bootstrap variables (generated automatically based on how app is called)

## The location of the civicrm-buildkit tree
# PRJDIR=

## The location of the civicrm-buildkit binaries
# BINDIR=

## A place to store temp files (PRJDIR/app/tmp)
# TMPDIR=

## A place to put sites that we build (PRJDIR/build)
# BLDDIR=

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

## Optional identifier to distinguish subsites in a multi-site build
## (default: default)
SITE_ID=default

## A unique token for this site used to secure any distributed civibuild tasks
## (default: random)
SITE_TOKEN=

## Root directory where the site's code will be installed
## (default: BLDDIR/SITE_NAME)
WEB_ROOT=

## Root directory where the site can put private (unpublished) data files
## (default: app/private/SITE_NAME)
PRIVATE_ROOT=

## Root directory where we store cached copies of git repositories
## (default: TMPDIR/git-cache)
CACHE_DIR=

## Time to wait before allowing updates to git/svn caches (seconds)
CACHE_TTL=60

## When updating a cache record, first attempt to lock it. Wait up to X seconds to acquire lock.
CACHE_LOCK_WAIT=120

## When checking out or updating git/svn, wait up to X seconds for process to complete
SCM_TIMEOUT=3600

###############################################################################
## "create" variables defined by civibuild

## Whether to destroy pre-existing source tree
FORCE_DOWNLOAD=

## Whether to destroy pre-existing DB's
FORCE_INSTALL=

## Whether the site has been previously installed
IS_INSTALLED=

## Default user accounts
ADMIN_EMAIL="admin@example.com"
ADMIN_PASS=
ADMIN_USER="admin"
DEMO_EMAIL="demo@example.com"
DEMO_PASS="demo"
DEMO_USER="demo"

## Printable name of the site (default: $SITE_NAME)
CMS_TITLE=

## The Drupal/WordPress/Joomla version (default: discretionary)
CMS_VERSION=

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
## (default: WEB_ROOT)
CMS_ROOT=

## DB credentials for CMS
## (suggested: autogenerate via 'amp create -f --root="$WEB_ROOT" --prefix=CMS_ --url="$CMS_URL"')
CMS_DB_DSN=
CMS_DB_ARGS=
CMS_DB_HOST=
CMS_DB_NAME=
CMS_DB_PASS=
CMS_DB_PORT=
CMS_DB_USER=

## Path to the civicrm-core tree
CIVI_CORE=

## DB credentials for Civi
## (suggested: autogenerate via 'amp create -f --root="$WEB_ROOT" --name=civi --prefix=CIVI_ --skip-url')
CIVI_DB_DSN=
CIVI_DB_ARGS=
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

## The name of the organization (for inclusion in footers, etc)
CIVI_DOMAIN_NAME=

## The default from email address
CIVI_DOMAIN_EMAIL=

## Path to the web-managed extension folder (optional)
CIVI_EXT_DIR=

## URL of the web-managed extension folder (required iff CIVI_EXT_DIR is set)
CIVI_EXT_URL=

## DB credentials for Civi test DB
## (suggested: autogenerate via 'amp create -f --root="$WEB_ROOT" --name=civi --prefix=TEST_ --skip-url')
TEST_DB_DSN=
TEST_DB_ARGS=
TEST_DB_HOST=
TEST_DB_NAME=
TEST_DB_PASS=
TEST_DB_PORT=
TEST_DB_USER=

###############################################################################
## snapshot-related variables
## (also used for cloning)

## Path to the directory which stores snapshots (default: PRJDIR/app/snapshot) [non-persistent]
SNAPSHOT_DIR=

## Name of the subdirectory containing the snapshot (default: SITE_NAME) [non-persistent]
SNAPSHOT_NAME=

## Path to database dump file (default: SNAPSHOT_DIR/SNAPSHOT_NAME/civi.sql.gz) [non-persistent]
CIVI_SQL=

## True if we should skip loading CIVI_SQL [non-persistent]
CIVI_SQL_SKIP=

## Path to database dump file (default: SNAPSHOT_DIR/SNAPSHOT_NAME/cms.sql.gz) [non-persistent]
CMS_SQL=

## True if we should skip loading CMS_SQL [non-persistent]
CMS_SQL_SKIP=

## True if we should skip loading TEST_SQL [non-persistent]
TEST_SQL_SKIP=

###############################################################################
## Clone-related variables

## Unique name of a particular clone
CLONE_ID=

## Base directory in whch we store clones metadata
## [default: app/clone/$SITE_NAME/$SITE_ID ]
CLONE_ROOT=

## Directory storing the activty clone's metadata
## [default: $CLONE_ROOT/$CLONE_ID]
CLONE_DIR=

###############################################################################
## Upgrade-testing variables

## Directory which stores the normal snapshots for upgrade-testing
UPGRADE_DATA_DIR="$PRJDIR/vendor/civicrm/upgrade-test/databases"

## Directory where the civibuid can put debug output about this site
UPGRADE_LOG_DIR=

###############################################################################
## "show" variables

## Path the HTML output directory
SHOW_HTML=

## Path to the last git summary file (from "git scan export")
## (Default: TMPDIR/git-scan-$SITE_NAME-last.json)
SHOW_LAST_SCAN=

## Path to which we will write a new git summary file (using "git scan export")
## (Default: TMPDIR/git-scan-$SITE_NAME-new.json)
SHOW_NEW_SCAN=

###############################################################################
## List of variables to save in the site's data file for use in future
## invocations
PERSISTENT_VARS="
  ADMIN_EMAIL ADMIN_PASS ADMIN_USER
  DEMO_EMAIL DEMO_PASS DEMO_USER
  CMS_TITLE CMS_URL CMS_ROOT CMS_VERSION
  CMS_DB_DSN CMS_DB_USER CMS_DB_PASS CMS_DB_HOST CMS_DB_PORT CMS_DB_NAME CMS_DB_ARGS
  CIVI_CORE CIVI_SITE_KEY CIVI_VERSION
  CIVI_DB_DSN CIVI_DB_USER CIVI_DB_PASS CIVI_DB_HOST CIVI_DB_PORT CIVI_DB_NAME CIVI_DB_ARGS
  TEST_DB_DSN TEST_DB_USER TEST_DB_PASS TEST_DB_HOST TEST_DB_PORT TEST_DB_NAME TEST_DB_ARGS
  CIVI_SETTINGS CIVI_FILES CIVI_TEMPLATEC CIVI_UF
  IS_INSTALLED
  SITE_TOKEN SITE_TYPE
"
# ignore: runtime options like CIVI_SQL_SKIP and FORCE_DOWNLOAD
