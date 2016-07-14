# civicrm-buildkit

Buildkit is a collection of ~20 tools for developing and testing CiviCRM.
These tools are referenced in the CiviCRM developer documentation.

Many of these tools are commonly used by web developers, so you may have
already installed a few.  Even so, it's generally easier to download the
full collection -- installing each individually takes a lot of work.

This is the same collection of tools which manages the test/demo/release
infrastructure for civicrm.org.

## Download

 * [Full Download: Ubuntu](doc/download-ubuntu.md) - Download buildkit and all system dependencies (mysql, etc). This is ideal when setting up a new, clean Ubuntu host.
 * [Full Download: Vagrantbox](https://github.com/civicrm/civicrm-buildkit-vagrant) - Download a prepared virtual-machine with all system dependencies (mysql, etc). This is ideal for Windows and OS X.
 * [Manual Download](doc/download-manual.md) - Just download buildkit and its tools. This is ideal if you have already installed the system dependencies (mysql, etc).

After you've downloaded buildkit the first time, you should periodically [update the tools](doc/download-update.md).

## CLI Setup

Buildkit includes many commands.  To access these on the command-line in a standard way, [configure the `PATH`](doc/cli-persistent.md).

If you are a more sophisticated developer who wishes to have multiple copies of your tools, then you can
[configure the `PATH` temporarily](doc/cli-temporary.md).

## CLI Tools

 * CiviCRM
   * [civix](https://github.com/totten/civix) - Generate skeletal code for CiviCRM extensions.
   * [civistrings](https://github.com/civicrm/civistrings) - Scan code for translatable strings (*.pot).
   * [cividist](https://github.com/civicrm/civicrm-buildkit/blob/master/doc/cividist.md) - Generate tarballs from a series of git branches/tags
   * [cv](https://github.com/civicrm/cv) - Execute custom PHP in Civi
 * Dependency management
   * [composer](http://getcomposer.org/) - Manage dependencies for PHP code.
   * [bower](http://bower.io/) - Manage dependencies for Javascript code.
 * Source code management
   * [git-scan](https://github.com/totten/git-scan/) - Manage a large number of git repositories.
   * [gitify](doc/gitify.md) - Convert a CiviCRM installation to a git repo.
   * [hub](http://hub.github.com/) - Send commands to github.com.
 * Source code quality
   * **civilint** - Check the syntax of uncommitted files using **phpcs**, **jshint**, etc.
   * [jshint](http://jshint.com/) - Check the syntax of Javascript files.
   * [phpcs](https://github.com/squizlabs/PHP_CodeSniffer) - Check the syntax of PHP files.
   * [coder 2.x (Civi)](https://github.com/civicrm/coder) - Configure phpcs for Civi code style. Derived from [coder 2.x](https://www.drupal.org/project/coder). (The [Civi coding standard](http://wiki.civicrm.org/confluence/display/CRMDOC/PHP+Code+and+Inline+Documentation) derives from the [Drupal coding standard](https://www.drupal.org/coding-standards) with variations for class/function/variable naming.)
 * Site management
   * [amp](https://github.com/totten/amp) - Abstracted interface for local httpd/sql service (Apache/nginx/MySQL).
   * [civibuild](doc/civibuild.md) - Build a complete source tree (with CMS+Civi+addons), provision httpd/sql, etc.
   * **civihydra** - Create a series test sites for several CMSs. (Extends `civibuild`.)
   * [drush](http://drush.ws/) - Administer a Drupal site.
   * [joomla](https://github.com/joomlatools/joomla-console) (joomla-console) - Administer a Joomla site.
   * [wp](http://wp-cli.org/) (wp-cli) - Administer a WordPress site.
 * Testing
   * [civicrm-upgrade-test](https://github.com/civicrm/civicrm-upgrade-test) - Scripts and data files for testing upgrades.
   * [karma](http://karma-runner.github.io) (w/[jasmine](http://jasmine.github.io/)) - Unit testing for Javascript.
   * [paratest](https://github.com/brianium/paratest) - Parallelized version of PHPUnit.
   * [phpunit](http://phpunit.de/) - Unit testing for PHP (with Selenium and DB add-ons).

## Documentation

 * [Civibuild: Create a full dev/demo build](doc/civibuild.md)
 * [Daily Coding: First Pull-Request, Housekeeping, etc](doc/daily-coding.md)
 * [Experimental: Multiple demo/training sites](doc/demo-sites.md)
