# Daily Coding

## Your First Pull-Request

(TODO: Write a real tutorial!)

Suppose we've just downloaded buildkit and want to prepare a patch for
CiviCRM 4.5.  This requires downloading and installing the bleeding edge
(4.5.x) code for CiviCRM+CMS as well as writing and publishing the patch.

```bash
## Download Drupal 7.x and CiviCRM 4.5.x
civicrm-buildkit$ civibuild create drupal-demo --civi-ver 4.5 --url http://localhost:8001

## Create a "fork" of civicrm-core on github.com for publishing changes
civicrm-buildkit$ cd build/drupal-demo/sites/all/modules/civicrm
civicrm$ hub fork

## Create some changes locally
civicrm$ git checkout origin/4.5 -b 4.5-mypatch
civicrm$ vi CRM/Utils/Array.php
civicrm$ civilint CRM/Utils/Array.php
## Repeat vi/civilint until clean
civicrm$ git commit CRM/Utils/Array.php

## Publish our changes on github.com
civicrm$ git push mygithubuser 4.5-mypatch
civicrm$ hub pull-request -b 4.5

## Make further changes based on feedback
civicrm$ vi CRM/Utils/Array.php
civicrm$ civilint CRM/Utils/Array.php
civicrm$ git commit CRM/Utils/Array.php
civicrm$ git push mygithubuser
```

Please note: A build may include several different git repositories. The
commands should look about the same on any repository, although different
git repositories may use different names for their versions/branches (eg the
civicrm-core, civicrm-joomla, and civicrm-wordpress repositories have
branches named "4.5", but the civicrm-drupal repository has a branch named
"7.x-4.5").

## Housekeeping

(TODO: Write a real tutorial!)

From time-to-time, you may want to update your code. It's also a good idea
to double-check that your git repos have checked out the normal/expected
branches.

```bash
civicrm-buildkit$ cd build/drupal-demo

drupal-demo$ git scan status
## If any repos look unclean, figure out why... and clean them up!

## Then:
drupal-demo$ git scan update

## If you think the DB or config structure has changed, then optionally:
drupal-demo$ civibuild reinstall drupal-demo
```

## Unit Tests

```bash
civicrm-buildkit$ cd build/drupal-demo/sites/all/modules/civicrm/tools

## Run all the API tests
tools$ ./scripts/phpunit api_v3_AllTests

## Run a single test class
tools$ ./scripts/phpunit api_v3_ContactTest

## Run a single test function in a single test class
tools$ ./scripts/phpunit --filter testCreateNameOrganization api_v3_ContactTest
```

## Upgrade Tests

When one makes a schema change, one must also prepare and test an upgrade
script. The basic cycle is:

 1. Modify the upgrade script (*.mysql or *.php -- eg CRM/Upgrade/Incremental/php/FourFive.php)
 2. Load a DB snapshot from an older version (e.g. CiviCRM 4.3.0)
 3. Execute the upgrade script
 4. Repeat until the upgrade works as expected

You can do these steps manually. Of course, it's a bit tedious to generate
and track the DB snapshots while reloading them and rerunning the upgrade
logic.  If you're particularly impatient/mindless (like me), you can use the
command:

```bash
civibuild upgrade-test BUILDNAME SQLFILE
```

For example:

```bash
civicrm-buildkit$ cd build/drupal-demo/sites/all/modules/civicrm
civicrm$ vi CRM/Upgrade/Incremental/php/FourFive.php
civicrm$ civibuild upgrade-test drupal-demo 4.3.0-setupsh.sql.bz2
## Uhoh, that didn't work! Try again...
civicrm$ vi CRM/Upgrade/Incremental/php/FourFive.php
civicrm$ civibuild upgrade-test drupal-demo 4.3.0-setupsh.sql.bz2
## Hooray! It worked.
```

The file "4.3.0-setupsh.sql.bz2" is a standard DB snapshot bundled with
buildkit -- it contains a database from CiviCRM 4.3.0 with
randomly-generated data.  The "upgrade-test" command will load
"4.3.0-setupsh.sql.bz2", execute a headless upgrade, and write any errors to
the log.  (See console output for details.)

Of course, it's fairly common to encounter different upgrade issues
depending on the original DB -- an upgrade script might work if the original
DB is v4.3 but fail for v4.2.  It's a good idea to test your upgrade logic
against multiple versions:

```bash
civicrm$ civibuild upgrade-test drupal-demo '4.2.*' '4.3.*' '4.4.*'
```

All of the tests above use standard DB snapshots with randomly-generated
data.  If you want to test something more specific, then create your own DB
snapshot and use it, eg:

```bash
## Make your own DB with weird data; save a snapshot
civicrm$ echo "update civicrm_contact set weird=data" | mysql exampledbname
civicrm$ mysqldump exampledbname | gzip > /tmp/my-snapshot.sql.gz
## Write some upgrade logic & try it
civicrm$ vi CRM/Upgrade/Incremental/php/FourFive.php
civicrm$ civibuild upgrade-test drupal-demo /tmp/my-snapshot.sql.gz
## Uhoh, that didn't work! Try again...
civicrm$ vi CRM/Upgrade/Incremental/php/FourFive.php
civicrm$ civibuild upgrade-test drupal-demo /tmp/my-snapshot.sql.gz
## Hooray! It worked.
```

If at any point you need to backout and load a "known-working" database,
then use the DB created by the original build:

```bash
$ civibuild restore drupal-demo
```
