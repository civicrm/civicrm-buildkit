## CiviDist
Cividist generates tarballs from the git repos. If you wish to run it with your own repos you will need to do the 2
setup steps first and then the last 3 when you want to build new tarballs (e.g nightly).

CiviDist works by checking out the matching branch in each repo - so if you want to use a non-standard name it must 
exist in all repos.

## Setup: Make the web root
```
civibuild create dist --url http://dist.localhost ; 
```

## Setup: Register your forks
 Note that if you don't fork one of these repos then you should still add a fork,
 but point it to the main civicrm repo so you have a consistent remote alias for all relevant repos.

```
cd build/dist/src
git remote add myfork https://github.com/myfork/civicrm-core.git
git config core.filemode false

cd build/dist/src/drupal
git remote add myfork https://github.com/myfork/civicrm-drupal.git
git config core.filemode false

cd build/dist/src/packages
git remote add myfork https://github.com/myfork/civicrm-packages.git
git config core.filemode false

cd build/dist/src/joomla
git remote add myfork https://github.com/myfork/civicrm-joomla.git
git config core.filemode false

cd build/dist/src/Wordpress
git remote add myfork https://github.com/myfork/civicrm-wordpress.git
git config core.filemode false
```

## Periodic: Update code - this will retrieve from the remote alias - ie. myfork in the text below
```
cd build/dist
env GIT_REMOTE=myfork cividist update 
```

## Periodic: Build tarballs
```
cd build/dist
cividist build myfork/4.6
```

## Periodic: Cleanup old/orphaned tarballs
```
cd build/dist
cividist prune
```
