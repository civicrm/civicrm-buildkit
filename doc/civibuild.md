# civibuild

Creating a full development environment for CiviCRM can be a lot of work, including:

 * Downloading / installing / configuring a CMS (Drupal, Joomla, WordPress)
 * Downloading / installing / configuring CiviCRM
 * Configuring Apache and MySQL
 * Configuring phpunit and selenium to connect to Civi

The *civibuild* command automates this process. It includes different
build-types, such as *drupal-clean* (a barebones Drupal+Civi site) and
*wp-demo* (a WordPress+Civi site with some example content).

Internally, civibuild uses commands like [drush](http://drush.ws/) and
[wp-cli](http://wp-cli.org/).

## Quickstart

```bash
## Configure "amp" with details of your Apache/MySQL environment.  Pay close
## attention to the instructions.  They may involve adding a line to your
## Apache configuration file.

$ amp config

## Test that "amp" has full and correct information about Apache/MySQL.
## Depending on the httpd confiuration, you may need to restart httpd
## and re-run "amp test" a few times.

$ amp test

## Create a new build using Drupal and Civi v4.5.  The command will
## print out URLs and credentials for accessing the website.

$ civibuild create drupal-demo --civi-ver 4.5 --url http://localhost:8001 --admin-pass s3cr3t
```

## Build Types

civibuild includes a small library of build scripts for different
configurations.  For example, at time of writing, it includes:

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

## Build Aliases

The build-types can be mixed/matched with different versions of Civi and of
the CMS. For example, one might say:

```bash
$ civibuild create drupal-civi44 --type drupal-demo --civi-ver 4.4 --url http://drupal-civi44.localhost
$ civibuild create drupal-civi45 --type drupal-demo --civi-ver 4.5 --url http://drupal-civi45.localhost
$ civibuild create wp-civi45--type wp-demo --civi-ver 4.5 --url http://wp-civi45.localhost
```

However, this is a bit cumbersome. Civibuild includes
[aliases](../src/civibuild.aliases.sh) to make this shorter:

```bash
$ civibuild create d44 --url http://d44.localhost
$ civibuild create d45 --url http://d45.localhost
$ civibuild create wp45 --url http://wp45.localhost
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
    <th>Metadata</th>
    <th>Code</th>
    <th>Config Files</th>
    <th>DB</th>
  </tr>
  </thead>
  <tbody>
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

For more details on how civicrm.settings.d works, see [app/civicrm.settings.d/README.txt](app/civicrm.settings.d/README.txt).

A parallel structure exists for the CMS settings files. See also:
 * [app/drupal.settings.d/README.txt](app/drupal.settings.d/README.txt)
 * [app/wp-config.d/README.txt](app/wp-config.d/README.txt)
