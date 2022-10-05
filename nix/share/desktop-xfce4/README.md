# Welcome, cividev (v2.0-alpha)

Welcome to the "cividev" virtual desktop. This environment is optimized for doing
application developing for CiviCRM.

## Desktop Localization

* Keyboard
    * To change the active keyboard layout, look in the main navbar. Click on the flag.
    * To add another keyboard, right-click on the flag. Choose "Keyboard settings" and "Layouts".
* Timezone
    * To change timezone, look in the main navbar. Right-click on the date/time.
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
* Open the CiviCRM code
    ```bash
    ## Locate the folder with CiviCRM source code. If you don't
    find -name Civi.php | xargs dirname

    # Open that folder in Visual Studio Code
    code ./dmaster/web/sites/all/modules/civicrm
    ```

## Profiles

This build includes multiple versions of PHP and MySQL, organized as _profiles_:

* `bknix-dfl`: The default profile with _typical_ versions of PHP, MySQL, etc.
* `bknix-min`: The minimum profile with the _oldest supported versions_ of PHP, MySQL, etc.
* `bknix-max`: The maximum profile with the _newest supported versions_ of PHP, MySQL, etc.
* `bknix-edge`: The bleeding-edge profile with very recent versions of PHP, MySQL, etc.

## Buildkit Updates

1. This VM includes buildkit, a collection of portable CLI tools. You may update these every few weeks. Here's how:
   * Open the "bknix-dfl" terminal
   * Download updates:
      ```
      git pull
      civi-download-tools
      ```
2. This VM also includes servers (Apache, PHP, MySQL, etc). You may update these every few months. Here's how:
   * If you previously launched the servers (`loco run`), then destroy them.
      * Stop the active processes (`Ctrl-C`)
      * Delete any runtime data (`loco clean`)
      * Close the terminal
   * Open a basic terminal
   * Download updates:
      ```
      cd ~/buildkit
      git pull
      ```
   * (*It is possible that the previous command will download an updated README. If so, close/reopen the README.*)
   * Apply the updates:
      ```
      PROFILES='dfl min max edge' ./nix/bin/install-desktop.sh xfce4
      ```

## System Summary

Here is a general description how this virtual desktop is configured:

* Install Debian "bullseye" with XFCE4.
* Uninstall large consumer packages that are unlikely to be used (multimedia, word-processing, etc).
* In /etc/sudoers.d, grant broad access to user "cividev".
* Install VM guest tools for:
	* x86: VirtualBox (`virtualbox-guest-x11` via `fasttrack`), VMWare (`open-vm-tools-desktop`), QEMU (`qemu-guest-agent spice-vdagent`)
	* arm64: QEMU (`qemu-guest-agent spice-vdagent`)
* Install "git", "curl", "wget", "psmisc".
* Install civicrm-buildkit in the desktop style ("./nix/bin/install-desktop.sh xfce4").
* In "bknix-dfl", start servers, create stateless helper sites (`civibuild create site-list`, `civibuild create phpmyadmin`), and stop servers.
* Install Visual Studio Code (DEB) and gedit.
* Tweak desktop:
    * Add some likely keyboard layouts
    * In main nav-bar, add browser icon. Add terminal submenu. (bknix-dfl, bknix-min, etc). Remove secondary navbar.
    * In "File Manager", add short-cut to "buildkit/build"
    * In browser, copy bookmarks for "Site list", "phpMyAdmin", and "Mailhog"
    * Tweak keyboard speed (eg repeat ~500ms ~25hz)
    * In VS Code:
        * Add PHP Extension Pack
        * Set theme to "Default Light+"
        * Disable minimap
        * Add launch config to `~/.config/Code/User/settings.json` ("Listen for XDebug", "Run PHPUnit (headless)", "Run PHPUnit (E2E)")
    * In "Display", set resolution to 1440x900
* Cleanup `buildkit/build`, `.ssh`, browser cache, APT cache, nix-collect-garbage
