#!/usr/bin/env bash

## These source-code repositories are commonly used, so we'll declare them once.
##
## To declare more repositories, add more calls to "git_cache_setup" or
## "svn_cache_setup" in this file OR in your build's "download.sh".
##
## GIT NOTES:
##  - To warm-up the cache, run "git_cache_setup <remote-url> <local-cache>"
##    at the beginning of the build process.
##  - To checkout the code, use "git clone file://<local-cache>"
##  - After download completes, we automatically change the origin URL
##    by running "git_cache_deref_remotes".
## SVN NOTES:
##  - To warm-up the cache, run "svn_cache_setup" at the beginning
##    of the build process.
##  - To checkout the code, use "svn_cache_clone" (instead of "svn co")

function git_cache_map() {
  case "$1" in
    "civicrm/civicrm-backdrop")                echo "https://github.com/civicrm/civicrm-backdrop.git" ; ;;
    "civicrm/civicrm-core")                    echo "https://github.com/civicrm/civicrm-core.git" ; ;;
    "civicrm/civicrm-drupal")                  echo "https://github.com/civicrm/civicrm-drupal.git" ; ;;
    "civicrm/civicrm-drupal-8")                echo "https://github.com/civicrm/civicrm-drupal-8.git" ; ;;
    "civicrm/civicrm-packages")                echo "https://github.com/civicrm/civicrm-packages.git" ; ;;
    "civicrm/civicrm-joomla")                  echo "https://github.com/civicrm/civicrm-joomla.git" ; ;;
    "civicrm/civicrm-wordpress")               echo "https://github.com/civicrm/civicrm-wordpress.git" ; ;;
    "civicrm/civicrm-demo-wp")                 echo "https://github.com/civicrm/civicrm-demo-wp.git" ; ;;
    "civicrm/api4")                            echo "https://github.com/civicrm/api4.git" ; ;;
    "civicrm/org.civicoop.civirules")          echo "https://lab.civicrm.org/extensions/civirules.git" ; ;;
    "TechToThePeople/civisualize")             echo "https://lab.civicrm.org/extensions/civisualize.git" ; ;;
    "civicrm/org.civicrm.module.cividiscount") echo "https://lab.civicrm.org/extensions/cividiscount.git" ; ;;
    "civicrm/org.civicrm.contactlayout")       echo "https://github.com/civicrm/org.civicrm.contactlayout.git" ; ;;
    "backdrop/backdrop")                       echo "https://github.com/backdrop/backdrop.git" ; ;;
    *)                                         cvutil_fatal "Unrecognized cache id: $1"
  esac
}

git_cache_setup_id civicrm/civicrm-core civicrm/civicrm-packages
git_cache_setup_id civicrm/civicrm-backdrop civicrm/civicrm-drupal civicrm/civicrm-drupal-8 civicrm/civicrm-joomla civicrm/civicrm-wordpress
git_cache_setup_id civicrm/org.civicrm.module.cividiscount civicrm/org.civicrm.contactlayout
