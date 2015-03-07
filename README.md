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


## Documentation

 * [Civibuild: Creating standard builds](doc/civibuild.md)
 * [Daily Coding: First Pull-Request, Housekeeping, etc](doc/first-pr.md)
 * [Experimental: Multiple demo/training sites](doc/demo-sites.md)
