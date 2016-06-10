# civicrm-buildkit

Buildkit is a collection of ~20 tools for developing and testing CiviCRM.
These tools are referenced in the CiviCRM developer documentation.

Many of these tools are commonly used by web developers, so you may have
already installed a few.  Even so, it's generally easier to download the
full collection -- installing each individually takes a lot of work.

This is the same collection of tools which manages the test/demo/release
infrastructure for civicrm.org.

## Download: Option #1: Full Stack on New Ubuntu Host

If you have a new installation of Ubuntu 12.04 or 14.04, then you can download
everything -- buildkit and the system requirements -- with one command. This
command will install buildkit to `~/buildkit`:

```bash
curl -Ls https://civicrm.org/get-buildkit.sh | bash -s -- --full --dir ~/buildkit
```

Note:
 * When executing the above command, you should *not* run as `root`. However, you *should*
have `sudo` permissions.
 * The `--full` option is *very opinionated*; it specifically installs `php`, `apache`, and `mysql` (rather than `hvm`, `nginx`, `lighttpd`, or `percona`). If you try to mix `--full` with alternative systems, then expect conflicts.

## Download: Option #2: Vagrant on Windows, OS X, etal

If you use Windows or OS X, then [Vagrant](https://www.vagrantup.com/) provides a great way to setup
an Ubuntu VM. For more instructions, see [civicrm-buildkit-vagrant](https://github.com/civicrm/civicrm-buildkit-vagrant).

## Download: Option #3: Other Environments

You may install buildkit in other environments. The main pre-requisites are:

 * Bash (Unix shell)
 * Git
 * PHP 5.3+
 * NodeJS
 * Recommended: Apache 2.2+ and MySQL 5.1+ (client and server) (for [amp](https://github.com/totten/amp) and [civibuild](doc/civibuild.md))
 * Recommended: Linux or OS X

All pre-requisites must support command-line access using the standard command
names (`git`, `php`, `node`, `mysql`, `mysqldump`, etc). In some environments,
you may need to enable these commands by configuring `PATH` -- this is especially
true for MAMP, XAMPP, and other downloaded packages.
(See, e.g., [Setup Command-Line PHP](http://wiki.civicrm.org/confluence/display/CRMDOC/Setup+Command-Line+PHP).)

Once the pre-requisites are met, download buildkit to `~/buildkit` with these commands:

```bash
git clone https://github.com/civicrm/civicrm-buildkit.git ~/buildkit
cd ~/buildkit
./bin/civi-download-tools
```

## Staying Up-to-Date

The configurations and tools in buildkit are periodically updated. To get the latest, simply run:

```bash
cd ~/buildkit
git pull
./bin/civi-download-tools
```

### CLI Setup: Option #1: Persistent

It is useful to register buildkit in the `PATH`. This enables you to run commands
by entering a name (e.g.  `civix`) rather than a full path (e.g.
`/path/to/buildkit/bin/civix`).

If you want to ensure that these CLI tools are always available, then:
 
 1. Determine the location of your shell configuration file. This is usually `~/.bashrc`, `~/.bash_profile`, or `~/.profile`.
 2. At the end of the file, add `export PATH="/path/to/buildkit/bin:$PATH"` (*with proper adjustments to match your local system*).
 3. Close and reopen the terminal.
 4. Enter the command `which civibuild`. This should display a full-path. If nothing appears, then retry the steps.

### CLI Setup: Option #2: Temporary

Alternatively, if you're just getting started, or if you worry about
conflicts between buildkit and your existing tools, then you can
register buildkit in the PATH temporarily. Simply adapt and run the `export`
command directly in the terminal:

```bash
export PATH=/path/to/buildkit/bin:$PATH
```

You can restore the normal environment by closing the terminal and opening
a new one.

Each time you open a new terminal while working on Civi development, you
would need to re-run the `export` command.

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
