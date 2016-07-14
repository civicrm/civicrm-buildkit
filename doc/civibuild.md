# civibuild

Creating a full development environment for CiviCRM requires a lot of work, e.g.

 * Downloading / installing / configuring a CMS (Drupal, Joomla, WordPress)
 * Downloading / installing / configuring CiviCRM
 * Configuring Apache and MySQL
 * Configuring file permissions on data folders
 * Configuring a headless test database for phpunit
 * Configuring Selenium to connect to Civi

The *civibuild* command automates this process. It includes different
build-types that are useful for core development, such as *drupal-clean* (a
barebones Drupal+Civi site) and *wp-demo* (a WordPress+Civi site with some
example content).

Note: There are a number of build tools on the market which can, e.g.,
create a Drupal web site (like [drush](http://drush.ws/)) or WordPress web
site (like [wp-cli](http://wp-cli.org/)).  Civibuild does not aim to replace
these.  Unfortunately, such tools generally require extra work for a Civi
developer environment.  Civibuild works with these tools and and fills
in missing parts.

## Quickstart

```bash

## Install buildkit if not already done so

$ curl -Ls https://civicrm.org/get-buildkit.sh | bash -s -- --full --dir ~/buildkit

## Add the following to .bashrc to easily run kit commands

PATH=~/buildkit/bin:$PATH
export VISUAL=vim
export EDITOR="$VISUAL"

## Install other dependencies.  run:

$ civi-download-tools

## Configure "amp" with details of your Apache/MySQL environment.  Pay close
## attention to the instructions.  They may involve adding a line to your
## Apache configuration file.

$ amp config

## Test that "amp" has full and correct information about Apache/MySQL.  You
## may need to alternately restart httpd, re-run "amp test", and/or re-run
## "amp config" a few times.

$ amp test

## Create a new build using Drupal and the CiviCRM "master" branch.
## The command will print out URLs and credentials for accessing the website.

$ civibuild create dmaster --url http://localhost:8001 --admin-pass s3cr3t

# To install CiviCRM 4.6 with drupal-demo.  Note: the latest releave of 
# civivolunteer, 4.5-1.4, is only stable with CiviCRM version 4.6

$ civibuild create d46-demo --url http://localhost:8001 --admin-pass s3cr3t --civi-ver 4.6 --type drupal-demo

## If installing drupal-demo, fix the perms for civicrm tmp files
$ sudo chown -R www-data:www-data buildkit/build/d46-demo/sites/default/files
$ sudo chmod -R 777 buildkit/build/d46-demo/sites/default/files/civicrm/templates_c

## By default, buildkit installs an older version of CiviVolunteer which doesn't
## work with CiviCRM 4.6.  To get CiviVolunteer working, update to newer version:

$ cd buildkit/build/d46-demo/sites/all/modules/civicrm/tools/extensions/civivolunteer
$ drush civicrm-ext-disable org.civicrm.volunteer
$ git pull
$ git pull origin 4.5-1.4
$ git checkout 4.5-1.4
$ drush civicrm-ext-install org.civicrm.volunteer

```

## Build Types

civibuild includes a small library of build scripts for different
configurations.  For example, at time of writing, it includes:

 * *backdrop-clean*: A bare, "out-of-the-box" installation of Backdrop+CiviCRM
 * *backdrop-demo*: A demo site running Backdrop and CiviCRM
 * *backdrop-empty*: An empty Backdrop site (without CiviCRM). Useful for testing tarball installation.
 * *drupal-clean*: A bare, "out-of-the-box" installation of Drupal+CiviCRM
 * *drupal-demo*: A demo site running Drupal and CiviCRM
 * *drupal-empty*: An empty Drupal site (without CiviCRM). Useful for testing tarball installation.
 * *wp-demo*: A demo site running WordPress and CiviCRM
 * *wp-empty*: An empty WordPress site (without CiviCRM). Useful for testing tarball installation.
 * *hrdemo* A demo site running Drupal, CiviCRM, and CiviHR
 * *symfony*: An experimental hybrid site running Drupal 7, Symfony 2, and CiviCRM
 * *cxnapp*: A self-signed CiviConnect app based on the reference implementation.
 * *messages*: A backend service for delivering in-app messages (eg "Getting Started").
 * *extdir*: A mock website akin to civicrm.org/extdir/ . Useful for testing the extension download process.
 * *dist*: A website containing nightly builds akin to dist.civicrm.org. Useful for preparing CiviCRM tarballs.
 * *l10n*: WIP - A build environment for creating translation files.
 * *joomla-demo*: WIP/incomplete/broken

For a list of available build-types as well as documentation on writing build scripts,
see [app/config](/app/config).

Build types can be mixed/matched with different versions of Civi, e.g.

```bash
$ civibuild create my-drupal-civi44 \
  --type drupal-demo \
  --civi-ver 4.4 \
  --url http://my-drupal-civi44.localhost
$ civibuild create my-drupal-civi45 \
  --type drupal-demo \
  --civi-ver 4.5 \
  --url http://my-drupal-civi45.localhost
$ civibuild create my-wordpress-civi45 \
  --type wp-demo \
  --civi-ver 4.5 \
  --cms-ver 4.0 \
  --url http://my-wp-civi45.localhost
```

## Build Aliases

For developers who work with several CMSs and several versions of Civi, it's
useful to have a naming convention and shorthand for the most common
configurations.  Civibuild includes [aliases](../src/civibuild.aliases.sh)
like "d44" and "wpmaster":

```bash
## Create a build "d44" using build-type "drupal-demo" with Civi "4.4"
$ civibuild create d44 --url http://d44.localhost

## Create a build "d45" using build-type "drupal-demo" with Civi "4.5"
$ civibuild create d45 --url http://d45.localhost

## Create a build "wp45" using build-type "wp-demo" with Civi "4.5"
$ civibuild create wp45 --url http://wp45.localhost

## Create a build "wpmaster" using build-type "wp-demo" with Civi's "master" branch
$ civibuild create wpmaster --url http://wpmaster.localhost
```

These aliases exactly match the demo sites deployed under civicrm.org (e.g.
"wp45" produces the demo site "wp45.demo.civicrm.org").

## Rebuilds

If you're interested in working on the build types or build process, then the workflow will consist of alternating two basic steps: (1) editing build scripts and (2) rebuilding. Rebuilds may take a few minutes, so it's helpful to choose the fastest type of rebuild that will meet your needs.

There are four variations on rebuilding. In order of fastest (least thorough) to slowest (most thorough):

<table>
  <thead>
  <tr>
    <th>Command</th>
    <th>Description</th>
    <th>Civibuild Metadata</th>
    <th>Civi+CMS Code</th>
    <th>Civi+CMS Config</th>
    <th>Civi+CMS DB</th>
  </tr>
  </thead>
  <tbody>
  <tr>
    <td><b>civibuild restore &lt;name&gt;</b></td>
    <td>Restore DB from pristine SQL snapshot</td>
    <td>Preserve</td>
    <td>Preserve</td>
    <td>Preserve</td>
    <td>Destroy / Recreate</td>
  </tr>
  <tr>
    <td><b>civibuild reinstall &lt;name&gt;</b></td>
    <td>Rerun CMS+Civi "install" process</td>
    <td>Preserve</td>
    <td>Preserve</td>
    <td>Destroy / Recreate</td>
    <td>Destroy / Recreate</td>
  </tr>
  <tr>
    <td><b>civibuild create &lt;name&gt; --force</b></td>
    <td>Create site, overwriting any files or DBs</td>
    <td>Preserve</td>
    <td>Destroy / Recreate</td>
    <td>Destroy / Recreate</td>
    <td>Destroy / Recreate</td>
  </tr>
  <tr>
    <td><b>civibuild destroy &lt;name&gt; ; civibuild create &lt;name&gt;</b></td>
    <td>Thoroughly destroy and recreate everything</td>
    <td>Destroy / Recreate</td>
    <td>Destroy / Recreate</td>
    <td>Destroy / Recreate</td>
    <td>Destroy / Recreate</td>
  </tr>
  </tbody>
</table>

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

For more details on how civicrm.settings.d works, see [app/civicrm.settings.d/README.txt](/app/civicrm.settings.d/README.txt).

A parallel structure exists for the CMS settings files. See also:
 * [app/drupal.settings.d/README.txt](/app/drupal.settings.d/README.txt)
 * [app/wp-config.d/README.txt](/app/wp-config.d/README.txt)

## Development/Testing of `civibuild`

The tests for `civibuild` are stored in `tests/phpunit`.  These are
integration tests which create and destroy real builds on the local system.
To run them:

 * Configure `amp` (as above)
 * Ensure that a test site is configured (`civibuild create civibild-test --type empty`)
 * Run `phpunit4` or `env DEBUG=1 OFFLINE=1 phpunit4`
   * Note that the tests accept some optional environment variables:
      * `DEBUG=1` - Display command output as it runs
      * `OFFLINE=1` - Try to avoid unnecessary network traffic
