#!/bin/bash

###############################################################################
## Bootstrap variables (generated automatically based on how app is called)

## The location of the civicrm-buildkit tree
# PRJDIR=

## The location of the civicrm-buildkit binaries
# BINDIR=

## A place to store temp files
## (default-git: PRJDIR/app/tmp)
## (default-sys: CIVIBUILD_HOME/.civibuild/tmp
# TMPDIR=

## A place to put sites that we build
## (default-git: PRJDIR/build)
## (default-sys: CIVIBUILD_HOME)
# BLDDIR=

###############################################################################
## External variables (inherited from user's shell environment)

## Location of all mutable files (site-builds, logs, tmp data, etc).
## If blank/omitted, then use a default file structure relative to `civibuild`'s bin.
# CIVIBUILD_HOME=

## When looking for instructions to do a build, search this list of folders.
## (example: $HOME/.civibuild/types:/etc/civibuild/types:/usr/share/buildkit/app/config)
## (note: The built-in folder "$PRJDIR/app/config" is automatically appended.)
# CIVIBUILD_PATH=

###############################################################################
## Common variables

## The name of on-going action (eg "create" or "reset")
ACTION=

## Codename for the build instance
SITE_NAME=

## Codename for the build scripts (default: $SITE_NAME)
SITE_TYPE=

## Location of the build scripts (default: search $CIVIBUILD_PATH for $SITE_TYPE)
SITE_CONFIG_DIR=

## Optional identifier to distinguish subsites in a multi-site build
## (default: default)
SITE_ID=default

## A unique token for this site used to secure any distributed civibuild tasks
## (default: random)
SITE_TOKEN=

## Root directory where civibuild should put all downloaded code/files for this build
## (default: BLDDIR/SITE_NAME)
##
## Counter-intuitively, WEB_ROOT can be -- but is not necessarily -- the HTTP document root.  The
## the HTTP document root may be a subdir (e.g.  "./web" or "./htdocs"). That folder is
## specifically identified as CMS_ROOT.
WEB_ROOT=

## Root directory where the site can put private (unpublished) data files
## (default-git: app/private/SITE_NAME )
## (default-sys: WEB_ROOT/.civibuild/private)
PRIVATE_ROOT=

## Root directory where we store cached copies of git repositories
## (default-git: TMPDIR/git-cache)
## (default-sys: CIVIBUILD_HOME/.civibuild/cache)
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

## Store credentials in encrypted format
## (default: randomly generated)
CIVI_CRED_KEY=

## Digital signatures
## (default: randomly generated)
CIVI_SIGN_KEY=

## The CiviCRM API (default: randomly generated)
CIVI_SITE_KEY=

## The CiviCRM branch/version
CIVI_VERSION=master

## |-delimited list of patches to apply (after downloading)
## Ex: "https://github.com/civicrm/civicrm-core/pull/8022"
## Ex: ";civicrm-packages;/my/local/change-for-packages.patch"
PATCHES=

## |-delimited list of  to apply (after downloading)
## Ex: "relpath=https://example.com/file.zip"
EXTRA_DLS=

## Space-delimited list of extensions to download (via cv/civicrm.org)
EXT_DLs=

## A template for picking the default URL (using variable "SITE_NAME").
## Ex: "http://%SITE_NAME%.test"
## Ex: "%AUTO%"
##
## In "%AUTO%", normal sites use amp default (e.g. http://localhost:7979)
## but aliase use "http://%SITE_NAME%.test". This is for backward compatibility.
URL_TEMPLATE='%AUTO%'

###############################################################################
## "create" variables defined by */install.sh

## Public URL of the site
## May be set by user (with --url). If omitted, then */install.sh must set it.
## (suggested: autogenerate via amp)
CMS_URL=

## Path to the CMS's public-facing web content -- i.e. the HTTP document root.
## (default: WEB_ROOT)
## (suggested: WEB_ROOT/web)
##
## The CMS_ROOT can be -- but is not necessarily -- the root folder into which all files were
## downloaded.  The HTTP document root may be a subdir (e.g.  "./web" or "./htdocs").
## If you specifically need the folder into which code was downloaded, see WEB_ROOT.
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
CMS_DB_PERM=admin

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
CIVI_DB_PERM=super

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

## List of extensions to enable on `*-demo` builds
CIVI_DEMO_EXTS='civirules civisualize cividiscount org.civicrm.search_kit org.civicrm.search org.civicrm.contactlayout org.civicrm.angularprofiles org.civicrm.volunteer'

## DB credentials for Civi test DB
## (suggested: autogenerate via 'amp create -f --root="$WEB_ROOT" --name=civi --prefix=TEST_ --skip-url')
TEST_DB_DSN=
TEST_DB_ARGS=
TEST_DB_HOST=
TEST_DB_NAME=
TEST_DB_PASS=
TEST_DB_PORT=
TEST_DB_USER=
TEST_DB_PERM=super

###############################################################################
## snapshot-related variables
## (also used for cloning)

## Path to the directory which stores snapshots
## (default-git: PRJDIR/app/snapshot) [non-persistent]
## (default-sys: CIVIBUILD_HOME/.civibuild/snapshot) [non-persistent]
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
## (default-git: app/clone/$SITE_NAME/$SITE_ID)
## (default-sys: WEB_ROOT/.civibuild/clone/$SITE_ID)
CLONE_ROOT=

## Directory storing the activty clone's metadata
## [default: $CLONE_ROOT/$CLONE_ID]
CLONE_DIR=

###############################################################################
## PHPUnit Info variables
PHPUNIT_TGT_EXT=

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
## (default-git: TMPDIR/git-scan-$SITE_NAME-last.json)
## (default-sys: WEB_ROOT/.civibuild/git-scan-last.json)
SHOW_LAST_SCAN=

## Path to which we will write a new git summary file (using "git scan export")
## (default-git: TMPDIR/git-scan-$SITE_NAME-new.json)
## (default-sys: WEB_ROOT/.civibuild/git-scan-new.json)
SHOW_NEW_SCAN=

###############################################################################
## List of variables to save in the site's data file for use in future
## invocations
PERSISTENT_VARS="
  ADMIN_EMAIL ADMIN_PASS ADMIN_USER
  DEMO_EMAIL DEMO_PASS DEMO_USER
  CMS_TITLE CMS_URL CMS_ROOT WEB_ROOT CMS_VERSION
  CMS_DB_DSN CMS_DB_USER CMS_DB_PASS CMS_DB_HOST CMS_DB_PORT CMS_DB_NAME CMS_DB_ARGS
  CIVI_CORE CIVI_SITE_KEY CIVI_VERSION
  CIVI_DB_DSN CIVI_DB_USER CIVI_DB_PASS CIVI_DB_HOST CIVI_DB_PORT CIVI_DB_NAME CIVI_DB_ARGS
  TEST_DB_DSN TEST_DB_USER TEST_DB_PASS TEST_DB_HOST TEST_DB_PORT TEST_DB_NAME TEST_DB_ARGS
  CIVI_SETTINGS CIVI_FILES CIVI_TEMPLATEC CIVI_UF
  IS_INSTALLED
  EXT_DLS
  CIVI_CRED_KEY CIVI_SIGN_KEY SITE_TOKEN SITE_TYPE
"
# ignore: runtime options like CIVI_SQL_SKIP and FORCE_DOWNLOAD

###############################################################################
## Declare Actions
## Aliases must also be declared
DECLARED_ACTIONS="
  cache-warmup
  clone-create clone-destroy clone-show
  create
  destroy
  download dl
  edit
  env-info
  install reinstall
  list
  phpunit-info
  show
  snapshot snapshots
  restore restore-all
  upgrade-test ut
"

