#!/bin/bash
mkdir "$WEB_ROOT"

git_cache_setup "http://github.com/civicrm/civicrm-extdir-example.git" "$CACHE_DIR/civicrm/civicrm-extdir-example.git"
git clone "$CACHE_DIR/civicrm/civicrm-extdir-example.git" "$WEB_ROOT"
