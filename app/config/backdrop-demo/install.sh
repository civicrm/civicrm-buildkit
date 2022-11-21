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
  ## Setup CiviCRM
  echo '{"enable_components":["CiviEvent","CiviContribute","CiviMember","CiviMail","CiviReport","CiviPledge","CiviCase","CiviCampaign"]}' \
    | cv api setting.create --in=json
  civicrm_apply_demo_defaults
  ver=$(civicrm_get_ver "$CIVI_CORE")
  phpversioncheck=$(php -r "echo version_compare('$ver', '5.19', '>=');")
  if [ $phpversioncheck ]; then
    php "$SITE_CONFIG_DIR/module-enable.php" civicrm_webtest
  fi

  ## Setup welcome page
  cv scr "$SITE_CONFIG_DIR/install-welcome.php"

  ## Setup demo user
  backdrop_user "$DEMO_USER" "$DEMO_EMAIL" "$DEMO_PASS"
  if [ $phpversioncheck ]; then
    backdrop_user_role "$DEMO_USER" "civicrm_webtest_user"
  fi

  backdrop_po_import

  ## Setup demo extensions
  cv en --ignore-missing $CIVI_DEMO_EXTS

  ## Demo sites always disable email and often disable cron
  cv api StatusPreference.create ignore_severity=critical name=checkOutboundMail
  cv api StatusPreference.create ignore_severity=critical name=checkLastCron

  ## Setup CiviCRM dashboards
  INSTALL_DASHBOARD_USERS="$ADMIN_USER;$DEMO_USER" cv scr "$SITE_CONFIG_DIR/install-dashboard.php"

popd >> /dev/null
