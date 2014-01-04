# civicrm-buildkit (experimental)

civicrm-buildkit is a collection of tools and scripts for preparing a useful
CiviCRM development environment.

## Requirements

 * Shell (bash)
 * Git
 * PHP
 * MySQL (client/server)
 * Recommended: Apache/Nginx
 * Recommended: Ruby/Rake

## Installation

```bash
git clone https://github.com/civicrm/civicrm-buildkit.git
cd civicrm-buildkit/bin
./civi-download-tools
./amp config
./amp test
./civibuild create drupal-demo --civi-ver 4.4 --url http://localhost:8001
## FIXME: ./civibuild launch drupal-demo
```

The final command will print out URLs and credentials for accessing the
website.

## CLI Tools

civicrm-buildkit includes several utilities which are useful in developing
CiviCRM:

 * [amp](https://github.com/totten/amp) - Abstracted interface for local httpd/sql service (Apache/nginx/MySQL)
 * **civibuild** - CLI tool which builds a complete source tree (with CMS+Civi+addons), provisions httpd/sql, etc.
 * [composer](http://getcomposer.org/) - Dependency manager for PHP packages
 * [civix](https://github.com/totten/civix) - Code-generator for CiviCRM extensions
 * [git-scan](https://github.com/totten/git-scan/) - Git extension for working with many git repositories
 * [hub](http://hub.github.com/) - Git extension for easily working with GitHub (Note: Requires Ruby/Rake)
 * [drush](http://drush.ws/) - CLI administration tool for Drupal
 * [wp](http://wp-cli.org/) - CLI administration tool for WordPress

It will be handy to add these to your PATH:

```bash
export PATH=/path/to/civicrm-buildkit/bin:$PATH
```

(Note: Adjust as needed for your filesystem.) To automatically set this up
again each time you login, add the statement to ~/.bashrc or ~/.profile .

If you have already installed these tools or don't want them, then
simply skip this step.

## Build Types

civicrm-buildkit includes a small library of build scripts for different configurations.
For example, at time of writing, it includes:

 * *drupal-demo*: A basic demo site running Drupal and CiviCRM
 * *wp-demo*: A basic demo site running WordPress and CiviCRM
 * *symfony*: An experimental hybrid site running Drupal 7, Symfony 2, and CiviCRM

For a list of available build-types as well as documentation on writing build scripts,
see [app/config](app/config).
