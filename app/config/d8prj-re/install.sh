#!/bin/bash

## Transition: Old builds don't have "web/" folder. New builds do.
## TODO: Simplify sometime after Dec 2019
## install.sh -- Create config files and databases; fill the databases
[ -d "$WEB_ROOT/web" ] && CMS_ROOT="$WEB_ROOT/web"

###############################################################################
## Create virtual-host and databases

amp_install

###############################################################################
## Setup Drupal (config files, database tables)

drupal8_install
DRUPAL_SITE_DIR=$(_drupal_multisite_dir "$CMS_URL" "$SITE_ID")
pushd "${CMS_ROOT}/sites/${DRUPAL_SITE_DIR}" >> /dev/null
#  drush8 -y updatedb
#  drush8 -y en libraries

  cv core:install -f --cms-base-url="$CMS_URL" \
    -m "settings.userFrameworkResourceURL=[cms.root]/libraries/civicrm" \
    -m "siteKey=$CIVI_SITE_KEY"
  #  -m "db=$CIVI_DB_DSN" ## For two DBs
  drush8 -y en civicrm

  ## Setup demo user
  civicrm_apply_d8_perm_defaults
  drush8 -y user-create --password="$DEMO_PASS" --mail="$DEMO_EMAIL" "$DEMO_USER"
  drush8 -y user:role:add demoadmin "$DEMO_USER"
popd >> /dev/null
