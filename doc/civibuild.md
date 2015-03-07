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
