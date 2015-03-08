# civicrm-buildkit

Buildkit is a collection of ~20 tools for developing and testing CiviCRM.
These tools are referenced in the CiviCRM developer documentation.

Many of these tools are commonly used by web developers, so you may have
already installed a few.  Even so, it's generally easier to download the
full collection -- installing each individually takes a lot of work.

This is the same collection of tools which manages the test/demo/release
infrastructure for civicrm.org.

## Requirements

 * Bash (Unix shell)
 * Git
 * PHP 5.3+ (For MAMP/XAMPP/etc, see [Setup Command-Line PHP](http://wiki.civicrm.org/confluence/display/CRMDOC/Setup+Command-Line+PHP))
 * [NodeJS](http://nodejs.org/)
 * Recommended: Apache 2.2+ and MySQL 5.1+ (client and server) (for [amp](https://github.com/totten/amp) and [civibuild](doc/civibuild.md))
 * Recommended: Ruby/Rake (for [hub](http://hub.github.com/))

## Download

```bash
git clone https://github.com/civicrm/civicrm-buildkit.git buildkit
cd buildkit
./bin/civi-download-tools
```

## Upgrade

```bash
cd buildkit
git pull
./bin/civi-download-tools
```

### CLI Setup: Persistent

It is useful to register buildkit in the PATH. This enables you to run commands
by entering a name (e.g.  "civix") rather than a full path (e.g.
"/path/to/buildkit/bin/civix").

```bash
export PATH=/path/to/buildkit/bin:$PATH
```

If you want to ensure that these CLI tools are always available, then edit
~/.bashrc or ~/.profile, add buildkit to your PATH, and restart the
terminal.

### CLI Setup: Temporary

Alternatively, if you're just getting started, or if you worry about
conflicts between buildkit and your existing tools, then you can
register buildkit in the PATH temporarily. Simply run the ***export***
command directly in the terminal -- do not edit ~/.bashrc or ~/.profile.

You can restore the normal environment by closing the terminal and opening
a new one.

Each time you open a new terminal while working on Civi development, you
would need to re-run ***export***.

## CLI Tools

 * CiviCRM
   * [civix](https://github.com/totten/civix) - Generate skeletal code for CiviCRM extensions.
   * [civistrings](https://github.com/civicrm/civistrings) - Scan code for translatable strings (*.pot).
   * **cividist** - Generate nightly tarballs from a series of git branches/tags
 * Dependency management
   * [composer](http://getcomposer.org/) - Manage dependencies for PHP code.
   * [bower](http://bower.io/) - Manage dependencies for Javascript code.
 * Source code management
   * [git-scan](https://github.com/totten/git-scan/) - Manage a large number of git repositories.
   * [gitify](doc/gitify.md) - Convert a CiviCRM installation to a git repo.
   * [hub](http://hub.github.com/) - Send commands to github.com (Note: Requires Ruby/Rake).
 * Source code quality
   * **civilint** - Check the syntax of uncommitted files using **phpcs**, **jshint**, etc.
   * [jshint](http://jshint.com/) - Check the syntax of Javascript files.
   * [phpcs](https://github.com/squizlabs/PHP_CodeSniffer) - Check the syntax of PHP files.
   * [coder 2.x (Civi)](https://github.com/civicrm/coder) - Configure phpcs for Civi code style. Derived from [coder 2.x](https://www.drupal.org/project/coder). (The [Civi coding standard](http://wiki.civicrm.org/confluence/display/CRMDOC/PHP+Code+and+Inline+Documentation) derives from the [Drupal coding standard](https://www.drupal.org/coding-standards) with variations for class/function/variable naming.)
 * Site management
   * [amp](https://github.com/totten/amp) - Abstracted interface for local httpd/sql service (Apache/nginx/MySQL).
   * [civibuild](doc/civibuild.md) - Build a complete source tree (with CMS+Civi+addons), provision httpd/sql, etc.
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
