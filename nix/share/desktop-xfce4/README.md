# Welcome, cividev (v2.0-alpha-arm64)

Welcome to the "cividev" virtual desktop. This environment is optimized for doing
application developing for CiviCRM.

## Desktop Localization

* Keyboard
    * To change the active keyboard layout, look in the top navbar. Click on the flag.
    * To add another keyboard, right-click on the flag. Choose "Keyboard settings" and "Layouts".
* Timezone
    * To change timezone, look in the top navbar. Right-click on the date/time.
      Choose "Properties". For "Timezone", type the name of your continent (eg "Europe/" or "America/").

## Quick Start

* On the desktop, open the "bknix-dfl" terminal
* In tab #1, launch servers (Apache, PHP, MySQL, etc)
   * Enter the command `loco run`.
   * Observe the final summary has a list of running services.
   * Keep this tab open. You may shutdown services by pressing "Ctrl-C".
* In tab #2, create a new site (or a restore a previous site). Here are some examples:
   ```bash
   ## Create a new site (Drupal)
   civibuild create dmaster

   ## Create a new site (WordPress)
   civibuild create wpmaster

   ## Restore a previous site (Drupal)
   civibuild restore dmaster
   civibuild show dmaster

   ## Restore a previous site (WordPress)
   civibuild restore wpmaster
   civibuild show wpmaster
   ```
* Open the site in a web browser
   * Tip: Look at the summary provided by "civibuild".
     There will be a URL and username/password.
     Hold down "Ctrl" and click on the site URL.
* Open the site in VS Code
   * Enter the command `code build/dmaster` or `code build/wpmaster`

## Profiles

This build includes multiple versions of PHP and MySQL, organized as _profiles_:

* `bknix-dfl`: The default profile with _typical_ versions of PHP, MySQL, etc.
* `bknix-min`: The minimum profile with the _oldest supported versions_ of PHP, MySQL, etc.
* `bknix-max`: The maximum profile with the _newest supported versions_ of PHP, MySQL, etc.
* `bknix-edge`: The bleeding-edge profile with very recent versions of PHP, MySQL, etc.

## Buildkit Updates

1. Buildkit includes a collection of portable CLI tools. You may update these every few weeks.
   * Open the "bknix-dfl" terminal
   * Download updates:
      ```
      git pull
      civi-download-tools
      ```
2. Buildkit also downloads servers (Apache, PHP, MySQL, etc). You may update these every few months.
   * Open the "bknix-dfl" terminal
   * If you have already launched the servers (`loco run`), then stop them (`Ctrl-C`)
     and delete any runtime data (`loco clean`).
   * Download updates:
      ```
      git pull
      PROFILES='dfl min max edge' ./nix/bin/install-desktop.sh xfce4
      ```

## System Summary

Here is a general description how this virtual desktop is configured:

* Install Debian "bullseye" with XFCE4.
* Uninstall large consumer packages that are unlikely to be used (multimedia, word-processing, etc).
* In /etc/sudoers.d, grant broad access to user "cividev".
* Install "git", "curl", "wget", "psmisc".
* Install civicrm-buildkit in the desktop style ("./nix/bin/install-desktop.sh xfce4").
* In "bknix-dfl", start servers, create stateless helper sites (`civibuild create site-list`, `civibuild create phpmyadmin`), and stop servers.
* Install Visual Studio Code (DEB) and gedit.
* Tweak desktop:
    * Add some likely keyboard layouts
    * In the nav-bar, copy icons to launch terminals (bknix-dfl, bknix-min, etc)
    * In "File Manager", add short-cut to "buildkit/build"
    * In browser, copy bookmarks for "Site list" and "Mailhog"
    * Tweak keyboard speed (eg repeat ~500ms ~25hz)
