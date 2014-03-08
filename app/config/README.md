Each subdirectory defines a "build" -- including the download and
installation process for a CMS+CiviCRM application.  For example, "wp-demo"
defines a CiviCRM demo site based on WordPress, and "drupal-hrdemo" defines
a CiviHR demo site based on Drupal.

Each directory includes the following required files:

 * download.sh -- Get the source code
 * install.sh -- Create config files and database tables
 * uninstall.sh -- Destroy config files and database tables

To make a new build, simply copy an existing one and edit the files
to-taste.

## Environment Variables ##

When writing these scripts, note the documentation in
[src/civibuild.defaults.sh](../../src/civibuild.defaults.sh).  This file lists
the environment variables which are (a) provided as inputs to the scripts
and (b) expected as outputs from the script.

## Available Commands ##

All the commands in civicrm-buildkit's "bin" directory are included in the
PATH. This specifically includes:

 * [amp](https://github.com/totten/amp)
 * [composer](http://getcomposer.org/)
 * [civix](https://github.com/totten/civix)
 * [drush](http://drush.ws/)
 * [wp](http://wp-cli.org/)

Additionally, note that standard POSIX commands (cp, mv, etc) will be
available, but they may use different implementations (GNU or BSD).

## Helper Functions ##

Several helper functions are automatically loaded from [src/civibuild.lib.sh](../../src/civibuild.lib.sh),
including:

 * drupal_install - Create Drupal config files, tables, and data dirs (using "drush site-install" and "sites/default")
 * wp_install - Create WordPress config files, tables, and data dirs (using wp-cli)
 * civicrm_install - Create CiviCRM config files, tables, and data dirs
