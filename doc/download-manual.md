# Download: Manual (Other Environments)

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

Once the pre-requisites are met, download buildkit to `~/buildkit`:

```bash
git clone https://github.com/civicrm/civicrm-buildkit.git ~/buildkit
cd ~/buildkit
./bin/civi-download-tools
```
