## CiviDist

`cividist` generates a website with tarballs built from the official git repos ([civicrm-core.git](https://github.com/civicrm/civicrm-core.git), [civicrm-packages.git](https://github.com/civicrm/civicrm-packages.git), etc). It manages the CiviCRM nightly builds (http://dist.civicrm.org).

If you wish to run `cividist` with your own repos, you will need to do the some initial setup and then periodically build new tarballs.

`cividist` expects that branch names match across all repos (e.g. the `4.6` branch in `civicrm-core.git` must match the `4.6` branch in `civicrm-packages.git`). If you use a non-standard branch name, it must exist in all repos.

## Setup: Make the web root

```
civibuild create dist --url http://dist.localhost
```

## Setup: Register your forks

Note: If you use forks, you should do so consistently across all repos (even if you don't
have any customizations on one repo or another). The goal is to consistently name the `remote`s
and `branch`es across all repos.

```
cd build/dist/src
git remote add myfork https://github.com/myfork/civicrm-core.git

cd build/dist/src/drupal
git remote add myfork https://github.com/myfork/civicrm-drupal.git

cd build/dist/src/packages
git remote add myfork https://github.com/myfork/civicrm-packages.git

cd build/dist/src/joomla
git remote add myfork https://github.com/myfork/civicrm-joomla.git

cd build/dist/src/Wordpress
git remote add myfork https://github.com/myfork/civicrm-wordpress.git
```

## Setup: Permissions

If your system has specific permission requirements, then apply the permissions as you normally would. For example, if you use chgrp and and set all files as group-writable:

```
sudo git config --system core.filemode false
sudo chgrp -R mygroup build/dist
sudo chmod -R g+w build/dist
```

## Periodic: Update tarballs

This will retrieve the latest code from the remote alias (eg `myfork`) and build new build tarballs:

```
cd build/dist
env GIT_REMOTE=myfork cividist update 
cividist build myfork/4.6
```

By default the tarballs will have the date in the name. If you don't want this you can add a FILE_SUFFIX
e.g to this command is used by Fuzion to a) use a remote called 'fuzion', b) use the branch 4.6.4rc1 from those repos & c) output using filenames like civicrm-4.6.5-drupal-nightly.tar.gz

```
env FILE_SUFFIX=nightly cividist build fuzion/4.6.4rc1
```

You can also build multiple tarballs with one command, e.g.

```
cividist build myfork/4.5 myfork/4.6 myfork/master
```

## Periodic: Cleanup old/orphaned tarballs

```
cd build/dist
cividist prune
```
