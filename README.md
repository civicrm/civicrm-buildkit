# civicrm-buildkit

A collection of tools and scripts for creating one or more CiviCRM development/demo/testing environments.

## Requirements

 * Shell (bash)
 * Git/SVN
 * PHP
 * MySQL (client/server)
 * NodeJS (for development with CiviCRM v4.6+)
 * Recommended: Apache (TODO: nginx)
 * Recommended: Ruby/Rake

## Installation

```bash
git clone https://github.com/civicrm/civicrm-buildkit.git
cd civicrm-buildkit/bin
./civi-download-tools
./amp config
## At this point, check to make sure you follow the instructions output by amp config,
## which involve adding a line to your Apache configuration file
./amp test
./civibuild create drupal-demo --civi-ver 4.5 --url http://localhost:8001
## FIXME: ./civibuild launch drupal-demo
```

The final command will print out URLs and credentials for accessing the
website.

## CLI Tools

civicrm-buildkit includes several utilities which are useful in developing
CiviCRM:

 * CiviCRM
   * [civix](https://github.com/totten/civix) - Code-generator for CiviCRM extensions
   * [civistrings](https://github.com/civicrm/civistrings) - String extractor
 * Dependency management
   * [composer](http://getcomposer.org/) - Dependency manager for PHP packages
   * [bower](http://bower.io/) - Dependency manager for frontend Javascript packages
 * Source code management
   * [git-scan](https://github.com/totten/git-scan/) - Git extension for working with many git repositories
   * [hub](http://hub.github.com/) - Git extension for easily working with GitHub (Note: Requires Ruby/Rake)
 * Source code quality
   * **civilint** - Wrapper script which calls all syntax checks (phpcs, jshint, etc) on uncommitted files.
   * [jshint](http://jshint.com/) - Javascript syntax checker
   * [phpcs](https://github.com/squizlabs/PHP_CodeSniffer) - PHP syntax checker
   * [coder 2.x (Civi)](https://github.com/civicrm/coder) - phpcs configuration derived from [coder 2.x](https://www.drupal.org/project/coder). (The [Civi coding standard](http://wiki.civicrm.org/confluence/display/CRMDOC/PHP+Code+and+Inline+Documentation) derives from the [Drupal coding standard](https://www.drupal.org/coding-standards) with variations for class/function/variable naming.)
 * Site management
   * [amp](https://github.com/totten/amp) - Abstracted interface for local httpd/sql service (Apache/nginx/MySQL)
   * **civibuild** - CLI tool which builds a complete source tree (with CMS+Civi+addons), provisions httpd/sql, etc.
   * [drush](http://drush.ws/) - CLI administration tool for Drupal
   * [joomla](https://github.com/joomlatools/joomla-console) (joomla-console) - CLI administration for Joomla
   * [wp](http://wp-cli.org/) (wp-cli) - CLI administration tool for WordPress
 * Testing
   * [civicrm-upgrade-test](https://github.com/civicrm/civicrm-upgrade-test) - Scripts and data files for testing upgrades
   * [karma](http://karma-runner.github.io) (w/[jasmine](http://jasmine.github.io/)) - Unit testing for Javascript (Note: Requires NodeJS)
   * [paratest](https://github.com/brianium/paratest) - Parallelized version of PHPUnit
   * [phpunit](http://phpunit.de/) - Unit testing for PHP (with Selenium and DB add-ons)

It will be handy to add these to your PATH:

```bash
export PATH=/path/to/civicrm-buildkit/bin:$PATH
```

(Note: Adjust as needed for your filesystem.) To automatically set this up
again each time you login, add the statement to ~/.bashrc or ~/.profile .

If you have already installed these tools or don't want them, then
simply skip this step.

## Build Types

civicrm-buildkit includes a small library of build scripts for different configurations.
For example, at time of writing, it includes:

 * *drupal-clean*: A bare, "out-of-the-box" installation of Drupal+CiviCRM
 * *drupal-demo*: A demo site running Drupal and CiviCRM
 * *wp-demo*: A demo site running WordPress and CiviCRM
 * *hrdemo* A demo site running Drupal, CiviCRM, and CiviHR
 * *symfony*: An experimental hybrid site running Drupal 7, Symfony 2, and CiviCRM
 * *extdir*: A mock website akin to civicrm.org/extdir/ . Useful testing the extension download process.
 * *dist*: A website containing nightly builds akin to dist.civicrm.org. Useful for preparing CiviCRM tarballs.
 * *l10n*: WIP - A build environment for creating translation files.
 * *joomla-demo*: WIP/incomplete/broken

For a list of available build-types as well as documentation on writing build scripts,
see [app/config](app/config).

## Rebuilds

If you're interested in working on the build types or build process, then the workflow will consist of alternating two basic steps: (1) editing build scripts and (2) rebuilding. Rebuilds may take a few minutes, so it's helpful to choose the fastest type of rebuild that will meet your needs.

There are four variations on rebuilding. In order of fastest (least thorough) to slowest (most thorough):

<table>
  <tr>
    <th>Command</th>
    <th>Description</th>
    <th>Metadata</th>
    <th>Code</th>
    <th>Config Files</th>
    <th>DB</th>
  </tr>
  <tr>
    <td><b>civibuild restore &lt;name&gt;</b></td>
    <td>Restore DB from pristine SQL snapshot</td>
    <td>Keep</td>
    <td>Keep</td>
    <td>Keep</td>
    <td>Recreate</td>
  </tr>
  <tr>
    <td><b>civibuild reinstall &lt;name&gt;</b></td>
    <td>Rerun CMS+Civi "install" process</td>
    <td>Keep</td>
    <td>Keep</td>
    <td>Recreate</td>
    <td>Recreate</td>
  </tr>
  <tr>
    <td><b>civibuild create &lt;name&gt; --force</b></td>
    <td>Create site, overwriting any files or DBs</td>
    <td>Keep</td>
    <td>Recreate</td>
    <td>Recreate</td>
    <td>Recreate</td>
  </tr>
  <tr>
    <td><b>civibuild destroy &lt;name&gt; ; civibuild create &lt;name&gt;</b></td>
    <td>Thoroughly destroy and recreate everything</td>
    <td>Recreate</td>
    <td>Recreate</td>
    <td>Recreate</td>
    <td>Recreate</td>
  </tr>
</table>

## Daily Coding: Your First Pull-Request

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
civicrm$ git commit CRM/Utils/Array.php

## Publish our changes on github.com
civicrm$ git push mygithubuser 4.5-mypatch
civicrm$ hub pull-request -b 4.5
```

Please note: A build may include several different git repositories. The
commands should look about the same on any repository, although different
git repositories may use different names for their versions/branches (eg the
civicrm-core, civicrm-joomla, and civicrm-wordpress repositories have
branches named "4.5", but the civicrm-drupal repository has a branch named
"7.x-4.5").


## Daily Coding: Housekeeping

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

## Daily Coding: Unit Tests

```bash
civicrm-buildkit$ cd build/drupal-demo/sites/all/modules/civicrm/tools

## Run all the API tests
tools$ ./scripts/phpunit api_v3_AllTests

## Run a single test class
tools$ ./scripts/phpunit api_v3_ContactTest

## Run a single test function in a single test class
tools$ ./scripts/phpunit --filter testCreateNameOrganization api_v3_ContactTest
```

## Daily Coding: Upgrade Tests

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

## civicrm.settings.php; settings.php; wp-config.php

There are a few CiviCRM settings which are commonly configured on a per-server
or per-workstation basis. For example, civicrm.org's demo server has ~10
sites running different builds (Drupal/WordPress * 4.4/4.5 * CiviCRM/CiviHR),
and visitors should not be allowed to download new extensions on any of those
sites. However, on the training server, trainees should be allowed to download
extensions. As discussed in
[Override CiviCRM Settings](wiki.civicrm.org/confluence/display/CRMDOC/Override+CiviCRM+Settings),
this setting (and many others) can be configured in civicrm.settings.php.

The civicrm.settings.php is created automatically as part of the build. One
could edit the file directly, but that means editing civicrm.settings.php
after every (re)build. The easiest way to customize the settings is to put
extra *.php files in /etc/civicrm.settings.d -- these files will be loaded
on every site that runs on this server (regardless of how many sites you
create or how many times you rebuild them).

For more details on how civicrm.settings.d works, see [app/civicrm.settings.d/README.txt](app/civicrm.settings.d/README.txt).

A parallel structure exists for the CMS settings files. See also:
 * [app/drupal.settings.d/README.txt](app/drupal.settings.d/README.txt)
 * [app/wp-config.d/README.txt](app/wp-config.d/README.txt)

## Experimental: Multiple demo/training sites

When creating a batch of identical sites for training or demonstrations,
one may want to create a single source-code-build with several
databases/websites running on top (using "Drupal multi-site"). To install
extra sites,  use the notation "civibuild create buildname/site-id" as in:

```bash
## Create the original build
civibuild create training --type drupal-demo --civi-ver 4.5 --url http://demo00.example.org --admin-pass s3cr3t

## Create additional sites (01 - 03)
civibuild create training/01 --url http://demo01.example.org --admin-pass s3cr3t
civibuild create training/02 --url http://demo02.example.org --admin-pass s3cr3t
civibuild create training/03 --url http://demo03.example.org --admin-pass s3cr3t

## Alternatively, create additional sites (01 - 20)
for num in $(seq -w 1 20) ; do
  civibuild create training/${num} --url http://demo${num}.example.org --admin-pass s3cr3t
done
```
