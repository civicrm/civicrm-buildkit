#!/usr/bin/env bash

## This file was used to pre-emptively hydrate many caches. The behavior is deprecated.
## Instead, you should declare caches in the map file (`src/civibuild.caches.sh`)
## and then call `git_cache_setup_id` as-needed.

git_cache_setup_id civicrm/civicrm-core civicrm/civicrm-packages
