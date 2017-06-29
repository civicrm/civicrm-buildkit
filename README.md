# civicrm-buildkit

Buildkit is a collection of ~20 tools for developing and testing CiviCRM.

## Documentation

For installation instructions and other documentation,
see [CiviCRM Developer Guide: Buildkit](https://docs.civicrm.org/dev/en/latest/tools/buildkit/).

## Bundled tools

<!-- see also: https://docs.civicrm.org/dev/en/latest/tools/#with-buildkit -->

* CiviCRM
    * [`civix`](https://github.com/totten/civix) - Generate skeletal code for CiviCRM extensions.
    * [`civistrings`](https://github.com/civicrm/civistrings) - Scan code for translatable strings (`*.pot`).
    * [`cividist`](https://docs.civicrm.org/dev/en/latest/tools/cividist/) - Generate tarballs from a series of git branches/tags.
    * [`cv`](https://github.com/civicrm/cv) - Administer a Civi DB. Execute custom PHP in Civi.
* Dependency management
    * [`composer`](http://getcomposer.org/) - Manage dependencies for PHP code.
    * [`bower`](http://bower.io/) - Manage dependencies for Javascript code.
* Source code management
    * [`git-scan`](https://github.com/totten/git-scan/) - Manage a large number of git repositories.
    * `gitify` - Convert a CiviCRM installation to a git repo.
    * [`hub`](http://hub.github.com/) - Send commands to `github.com`.
* Source code quality
    * `civilint` - Check the syntax of uncommitted files using `phpcs`, `jshint`, etc.
    * [`jshint`](http://jshint.com/) - Check the syntax of Javascript files.
    * [`phpcs`](https://github.com/squizlabs/PHP_CodeSniffer) - Check the syntax of PHP files.
    * [`coder` 2.x (Civi)](https://github.com/civicrm/coder) - Configure phpcs for Civi code style. Derived from [coder 2.x](https://www.drupal.org/project/coder). (The [Civi coding standard](http://wiki.civicrm.org/confluence/display/CRMDOC/PHP+Code+and+Inline+Documentation) derives from the [Drupal coding standard](https://www.drupal.org/coding-standards) with variations for class/function/variable naming.)
* Site management
    * [`amp`](https://github.com/totten/amp) - Abstracted interface for local httpd/sql service (Apache/nginx/MySQL).
    * [`civibuild`](https://docs.civicrm.org/dev/en/latest/tools/civibuild/) - Build a complete source tree (with CMS+Civi+addons), provision httpd/sql, etc.
    * `civihydra` - Create a series test sites for several CMSs. (Extends `civibuild`.)
    * [`drush` and `drush8`](http://drush.ws/) - Administer a Drupal site.
    * [`joomla`](https://github.com/joomlatools/joomla-console) (joomla-console) - Administer a Joomla site.
    * [`wp`](http://wp-cli.org/) (wp-cli) - Administer a WordPress site.
* Testing
    * [`civicrm-upgrade-test`](https://github.com/civicrm/civicrm-upgrade-test) - Scripts and data files for testing upgrades.
    * [`karma`](http://karma-runner.github.io) (w/[jasmine](http://jasmine.github.io/)) - Unit testing for Javascript.
    * [`paratest`](https://github.com/brianium/paratest) - Parallelized version of PHPUnit.
    * [`phpunit` and `phpunit4`](http://phpunit.de/) - Unit testing for PHP (with Selenium and DB add-ons).
