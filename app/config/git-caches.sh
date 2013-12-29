#!/bin/bash

## These git repos are commonly used, so we'll declare them once.
##
## To declare more repositories, add more calls to "git_cache_setup"
## in this file OR in your build's "download.sh"

git_cache_setup "https://github.com/civicrm/civicrm-core.git"                "$GIT_CACHE_DIR/civicrm/civicrm-core.git"
git_cache_setup "https://github.com/civicrm/civicrm-drupal.git"              "$GIT_CACHE_DIR/civicrm/civicrm-drupal.git"
git_cache_setup "https://github.com/civicrm/civicrm-packages.git"            "$GIT_CACHE_DIR/civicrm/civicrm-packages.git"
git_cache_setup "https://github.com/civicrm/civicrm-joomla.git"              "$GIT_CACHE_DIR/civicrm/civicrm-joomla.git"
git_cache_setup "https://github.com/civicrm/civicrm-wordpress.git"           "$GIT_CACHE_DIR/civicrm/civicrm-wordpress.git"
git_cache_setup "https://github.com/eileenmcnaughton/civicrm_developer.git"  "$GIT_CACHE_DIR/eileenmcnaughton/civicrm_developer.git"
