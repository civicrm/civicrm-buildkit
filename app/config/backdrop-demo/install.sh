#!/bin/bash

## install.sh -- Create config files and databases; fill the databases

## Transition: Old builds don't have "web/" folder. New builds do.
## TODO: Simplify sometime after Dec 2019
[ -d "$WEB_ROOT/web" ] && CMS_ROOT="$WEB_ROOT/web"

###############################################################################
## Create virtual-host and databases

amp_install

###############################################################################
## Setup Backdrop (config files, database tables)

backdrop_install

###############################################################################
## Setup CiviCRM (config files, database tables)

CIVI_DOMAIN_NAME="Demonstrators Anonymous"
CIVI_DOMAIN_EMAIL="\"Demonstrators Anonymous\" <info@example.org>"
CIVI_CORE="${CMS_ROOT}/modules/civicrm"
CIVI_SETTINGS="${CMS_ROOT}/civicrm.settings.php"
CIVI_FILES="${CMS_ROOT}/files/civicrm"
CIVI_TEMPLATEC="${CIVI_FILES}/templates_c"
CIVI_UF="Backdrop"
civicrm_install

###############################################################################
## Extra configuration

pushd "$CMS_ROOT" >> /dev/null
  php "$SITE_CONFIG_DIR/module-enable.php" civicrm
  civicrm_apply_demo_defaults
  ver=$(civicrm_get_ver "$CIVI_CORE")
  phpversioncheck=$(php -r "echo version_compare('$ver', '5.19', '>=');")
  if [ $phpversioncheck ]; then
    php "$SITE_CONFIG_DIR/module-enable.php" civicrm_webtest
  fi

  ## Setup demo user
  #drush -y en civicrm_webtest
  drush -y user-create --password="$DEMO_PASS" --mail="$DEMO_EMAIL" "$DEMO_USER"
  if [ $phpversioncheck ]; then
    echo 'INSERT IGNORE INTO users_roles (uid,role) SELECT uid, "civicrm_webtest_user" FROM users WHERE name = @ENV[DEMO_USER];' \
      | env DEMO_USER="$DEMO_USER" amp sql -Ncms -e
    #drush -y user-add-role civicrm_webtest_user "$DEMO_USER"
  fi

  cv en --ignore-missing civirules civisualize cividiscount org.civicrm.search org.civicrm.contactlayout org.civicrm.angularprofiles org.civicrm.volunteer

  ## Demo sites always disable email and often disable cron
  drush cvapi StatusPreference.create ignore_severity=critical name=checkOutboundMail
  drush cvapi StatusPreference.create ignore_severity=critical name=checkLastCron

popd >> /dev/null
