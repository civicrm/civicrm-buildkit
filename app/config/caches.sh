#!/usr/bin/env bash

## This file was used to define global prefetching for git caches. The behavior is deprecated.
##
## Instead, you should fetch caches as-needed. Either:
##  - Call `git_cache_setup` and then call `git clone`; or...
##  - Update `git_cache_map` and then call `git_cache_setup_id`

## If you really need a global prefetch, it would probably look like this:

## Setup cache by URL
#git_cache_setup https://example.com/my-repo "$CACHE_DIR/my/repo.git"

## Setup cache by ID (per git_cache_map)
#git_cache_setup_id civicrm/civicrm-core civicrm/civicrm-packages
