#!/usr/bin/env bash

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
  drush8 -y updatedb
popd >> /dev/null

###############################################################################
## Setup CiviCRM (config files, database tables)

CIVI_DOMAIN_NAME="Demonstrators Anonymous"
CIVI_DOMAIN_EMAIL="info@example.org"
CIVI_CORE="${WEB_ROOT}/vendor/civicrm/civicrm-core"
CIVI_UF="Drupal8"
GENCODE_CONFIG_TEMPLATE="${CMS_ROOT}/modules/contrib/civicrm/civicrm.config.php.drupal"

pushd "${CMS_ROOT}/sites/${DRUPAL_SITE_DIR}" >> /dev/null
  civicrm_install_cv
popd >> /dev/null

###############################################################################
## Extra configuration
pushd "${CMS_ROOT}/sites/${DRUPAL_SITE_DIR}" >> /dev/null

  ## make sure drush functions are loaded
  drush8 cc drush -y

  ## Setup CiviCRM
  if cv ev 'exit(version_compare(CRM_Utils_System::version(), "5.47.alpha", "<") ?0:1);' ; then
    echo '{"enable_components":["CiviEvent","CiviContribute","CiviMember","CiviMail","CiviReport","CiviPledge","CiviCase","CiviCampaign","CiviGrant"]}' \
      | drush8 cvapi setting.create --in=json
  else 
    echo '{"enable_components":["CiviEvent","CiviContribute","CiviMember","CiviMail","CiviReport","CiviPledge","CiviCase","CiviCampaign"]}' \
      | drush8 cvapi setting.create --in=json
  fi
  civicrm_apply_demo_defaults
  cv ev 'return CRM_Utils_System::synchronizeUsers();'

  ## Show errors on screen
  drush8 -y config:set system.logging error_level verbose

  ## Setup theme
  #above# drush8 -y en garland
  export SITE_CONFIG_DIR
  drush8 -y -u "$ADMIN_USER" scr "$SITE_CONFIG_DIR/install-theme.php"

  ## Based on the block info, CRM_Core_Block::CREATE_NEW and CRM_Core_Block::ADD should be enabled by default, but they aren't.
  ## "drush8 -y cc all" and "drush8 -y cc block" do *NOT* solve the problem. But this does:
  ## doesn't work on d8
  ## drush8 php-eval -u "$ADMIN_USER" 'module_load_include("inc","block","block.admin"); block_admin_display();'

  ## Setup welcome page
  drush8 -y scr "$SITE_CONFIG_DIR/install-welcome.php"

  ## Setup login_destination
  #above# drush8 -y en login_destination
  # doesn't work in d8 drush8 -y scr "$SITE_CONFIG_DIR/install-login-destination.php"

  ## Setup userprotect
  drush8 -y en userprotect
  drush8 -y rmp authenticated 'userprotect.account.edit,userprotect.mail.edit,userprotect.pass.edit'

  ## Setup demo user
  # drush8 -y en civicrm_webtest
  civicrm_apply_d8_perm_defaults
  drush8 -y user-create --password="$DEMO_PASS" --mail="$DEMO_EMAIL" "$DEMO_USER"
  drush8 -y user-add-role demoadmin "$DEMO_USER"
  # In Garland, CiviCRM's toolbar looks messy unless you also activate Drupal's "toolbar", so grant "access toolbar"
  # We've activated more components than typical web-test baseline, so grant rights to those components.
  drush8 -y rap demoadmin 'access toolbar,administer CiviCase,access all cases and activities,access my cases and activities,add cases,delete in CiviCase,administer CiviCampaign,manage campaign,reserve campaign contacts,release campaign contacts,interview campaign contacts,gotv campaign contacts,sign CiviCRM Petition,access CiviGrant,edit grants, delete in CiviGrant'

  # Move extensions into web accessible areas
  if [ -d "$CIVI_CORE/tools/extensions/org.civicrm.contactlayout" ]; then
    mv $CIVI_CORE/tools/extensions/org.civicrm.contactlayout files/civicrm/ext
  fi
  cv api extension.refresh

  ## Demo sites always disable email and often disable cron
  drush8 cvapi StatusPreference.create ignore_severity=critical name=checkOutboundMail
  drush8 cvapi StatusPreference.create ignore_severity=critical name=checkLastCron

  ## Setup CiviCRM dashboards
  INSTALL_DASHBOARD_USERS="$ADMIN_USER;$DEMO_USER" drush8 scr "$SITE_CONFIG_DIR/install-dashboard.php"

popd >> /dev/null
