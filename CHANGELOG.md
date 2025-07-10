# Changelog

Buildkit is periodically updated with newer versions of its tools.  Changes
are generally "drop-in" updates that don't require any special action. 
However, if a change requires special action, it should be documented in
this changelog.

### v25.04.0 => v25.06.0

Breaking changes:

* `civi-download-tools`: Drop support for `hub` ([#941](https://github.com/civicrm/civicrm-buildkit/pull/941)) and `joomlatools-console` ([#940](https://github.com/civicrm/civicrm-buildkit/pull/940))
* `civi-download-tools`: Drop support for the `--full` option ([#936](https://github.com/civicrm/civicrm-buildkit/pull/936))
* `civibuild`: Drop ancient aliases pegged to CiviCRM 4.x (e.g `d43` and `wp46`)
* `composer.json`: Drop support for PHP 7.2. Drop unused `paratest`. ([#944](https://github.com/civicrm/civicrm-buildkit/pull/944))
* `bin/securify`: Drop old script. (Deprecated circa 2019.)
* __Nix__: Drop ancient packages `php71`, `php72`, `mysql56`, `mariadb105` ([#926](https://github.com/civicrm/civicrm-buildkit/pull/926))
* __Nix__: Drop PHP's `imap` PECL ([#934](https://github.com/civicrm/civicrm-buildkit/pull/934))
* __Nix__: Change default domain-suffix in civibuild (`*.nip.io` => `*.civi.bid`) ([#954](https://github.com/civicrm/civicrm-buildkit/pull/954))
* __Vagrant__: Drop all support ([#937](https://github.com/civicrm/civicrm-buildkit/pull/937))

Additionally, several scripts have moved to their own folders. This should
not affect ordinary CLI usage for `buildkit/bin/`. However, it could affect
some overrides, customizations, forks, etc. This includes:

| From | To | See also |
| -- | -- | -- |
| `src/pogo/bknix-ci-cleanup.php`    | `tools/bknix-ci-cleanup/`     | [#948](https://github.com/civicrm/civicrm-buildkit/pull/948) |
| `src/pogo/civicredits.php`         | `tools/civicredits/`          | [#948](https://github.com/civicrm/civicrm-buildkit/pull/948) |
| `src/pogo/fetch-universe.php`      | `tools/fetch-universe/`       | [#948](https://github.com/civicrm/civicrm-buildkit/pull/948) |
| `src/pogo/find-stale-builds.php`   | `tools/find-stale-builds/`    | [#948](https://github.com/civicrm/civicrm-buildkit/pull/948) |
| `src/pogo/forkify.php`             | `tools/forkify/`              | [#948](https://github.com/civicrm/civicrm-buildkit/pull/948) |
| `src/pogo/import-rn.php`           | `tools/import-rn/`            | [#948](https://github.com/civicrm/civicrm-buildkit/pull/948) |
| `src/pogo/zipdiff.php`             | `tools/zipdiff/`              | [#948](https://github.com/civicrm/civicrm-buildkit/pull/948) |
| `src/releaser.php`                 | `tools/releaser/`             | [#956](https://github.com/civicrm/civicrm-buildkit/pull/956) |
| `extern/phpunit-xml-cleanup.php`   | `tools/phpunit-xml-cleanup/`  | [#951](https://github.com/civicrm/civicrm-buildkit/pull/951) |
| `phars.json`: `civici`             | `tools/civici/`               | [#953](https://github.com/civicrm/civicrm-buildkit/pull/953) |

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
