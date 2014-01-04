# civicrm-project (experimental)

civicrm-project is a collection of tools and scripts preparing a useful
CiviCRM development environment.

## Requirements

 * Shell (bash)
 * Git
 * PHP
 * MySQL (client/server)
 * Optional: Apache/Nginx

## Installation

```bash
git clone https://github.com/civicrm/civicrm-project.git
cd civicrm-project/bin
./civi-download-tools
./amp config
./amp test
./civibuild build drupal-demo --civi-ver=4.4 --url=http://localhost:8001
## FIXME: ./civibuild launch drupal-demo
```

The final command will print out URLs and credentials for accessing the
website.

## Installation: CLI Tools

The project bundles in several useful command-line tools (such as composer,
drush, wp-cli, and civix). It will be handy to add these to your PATH:

```bash
export PATH=/path/to/civicrm-project/bin:$PATH
```

(Note: Adjust as needed for your filesystem.) To automatically set this up
again each time you login, add the statement to ~/.bashrc or ~/.profile .

If you have already installed these tools or don't want them, then
simply skip this step.
