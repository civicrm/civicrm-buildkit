# Changelog

Buildkit is periodically updated with newer versions of its tools.  Changes
are generally "drop-in" updates that don't require any special action. 
However, if a change requires special action, it should be documented in
this changelog.

### v25.04.0 => v25.06.0

Breaking changes:

* `civi-download-tools`: Drop support for `hub` (#941) and `joomlatools-console` (#940)
* `civi-download-tools`: Drop support for the `--full` option (#936)
* `composer.json`: Drop support for PHP 7.2. Drop unused `paratest`. (#944)
* `bin/securify`: Drop old script. (Deprecated circa 2019.)
* __Nix__: Drop ancient packages `php71`, `php72`, `mysql56`, `mariadb105` (#926)
* __Nix__: Drop PHP's `imap` PECL (#934)
* __Vagrant__: Drop all support (#937)

Additionally, several scripts have moved to their own folders. This should
not affect ordinary CLI usage for `buildkit/bin/`. However, it could affect
some overrides, customizations, forks, etc. This includes:

| From | To |
| -- | -- |
| `extern/phpunit-xml-cleanup.php`   | `tools/phpunit-xml-cleanup/`  |
| `src/pogo/bknix-ci-cleanup.php`    | `tools/bknix-ci-cleanup/`     |
| `src/pogo/civicredits.php`         | `tools/civicredits/`          |
| `src/pogo/fetch-universe.php`      | `tools/fetch-universe/`       |
| `src/pogo/find-stale-builds.php`   | `tools/find-stale-builds/`    |
| `src/pogo/forkify.php`             | `tools/forkify/`              |
| `src/pogo/import-rn.php`           | `tools/import-rn/`            |
| `src/pogo/zipdiff.php`             | `tools/zipdiff/`              |

### v14.05.0 => v14.06.0

In version v14.05 (and earlier), each build included two databases: one CMS
database and one Civi database.  If you ran unit-tests in v14.05, the tests
would reset the Civi database -- which was problematic if you like to alternate
rapidly between unit-testing and manual testing (because any manual DB changes
are lost).

v14.06 addresses this by provisioning a third database for testing.  This
requires some changes &mdash; eg creating the database, saving the metadata (eg
"build/drupal-demo.sh"), and updating configs files (eg
"build/drupal-demo/sites/all/modules/civicrm/tests/phpunit/CiviTest/civicrm.settings.dist.php").
You can fix all of this by reinstalling the build (which will recreate all
databases and config files).  If the build is named "drupal-demo", then simply
run:

```bash
civibuild reinstall drupal-demo
```
