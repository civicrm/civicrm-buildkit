# Download: Manual (Other Environments)

You may install buildkit in other environments. The main pre-requisites are:

 * Linux or OS X
 * Git
 * PHP 5.3+ (Extensions: `bcmath curl gd gettext imap intl imagick json mbstring mcrypt openssl pdo_mysql phar posix soap zip`)
 * NodeJS (v5 recommended)
 * NPM 
 * Recommended (_for [amp](https://github.com/totten/amp) and [civibuild](doc/civibuild.md)_)
   * Apache 2.2 or 2.4 (Modules: `mod_rewrite`. On SUSE, possibly `mod_access_compat`. This list may not be exhaustive.)
   * MySQL 5.1+ (client and server)
 
All pre-requisites must support command-line access using the standard command
names (`git`, `php`, `node`, `mysql`, `mysqldump`, etc). In some environments,
you may need to enable these commands by configuring `PATH` -- this is especially
true for MAMP, XAMPP, and other downloaded packages.
(See, e.g., [Setup Command-Line PHP](http://wiki.civicrm.org/confluence/display/CRMDOC/Setup+Command-Line+PHP).)

Once the pre-requisites are met, download buildkit to `~/buildkit`:

```bash
git clone https://github.com/civicrm/civicrm-buildkit.git ~/buildkit
cd ~/buildkit
./bin/civi-download-tools
```

## Troubleshooting

* Nodejs version too old or npm update does not work

Download the latest version from nodejs.org and follow to their instructions

* Nodejs problems

It might be handy to run

```bash
npm update
npm install fs-extra
```
