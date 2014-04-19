#!/bin/bash

## install.sh -- Create config files and databases; fill the databases

###############################################################################
## Create virtual-host and databases

amp_install

###############################################################################
## Setup Drupal (config files, database tables)

drupal_install

###############################################################################
## Setup CiviCRM (config files, database tables)

DRUPAL_SITE_DIR=$(_drupal_multisite_dir "$CMS_URL" "$SITE_ID")
CIVI_DOMAIN_NAME="Demonstrators Anonymous"
CIVI_DOMAIN_EMAIL="\"Demonstrators Anonymous\" <info@example.org>"
CIVI_CORE="${WEB_ROOT}/sites/all/modules/civicrm"
CIVI_SETTINGS="${WEB_ROOT}/sites/${DRUPAL_SITE_DIR}/civicrm.settings.php"
CIVI_FILES="${WEB_ROOT}/sites/${DRUPAL_SITE_DIR}/files/civicrm"
CIVI_TEMPLATEC="${CIVI_FILES}/templates_c"
CIVI_EXT_DIR="${WEB_ROOT}/sites/${DRUPAL_SITE_DIR}/ext"
CIVI_EXT_URL="${CMS_URL}/sites/${DRUPAL_SITE_DIR}/ext"
CIVI_UF="Drupal"

civicrm_install

###############################################################################
## Extra configuration
pushd "${WEB_ROOT}/sites/${DRUPAL_SITE_DIR}" >> /dev/null

  drush -y updatedb
  drush -y en civicrm toolbar locale garland login_destination userprotect

  ## Setup CiviCRM
  echo '{"enable_components":["CiviEvent","CiviContribute","CiviMember","CiviMail","CiviReport","CiviPledge","CiviCase","CiviCampaign"]}' \
    | drush cvapi setting.create --in=json
  drush cvapi setting.create versionCheck=0
  drush cvapi MailSettings.create id=1 is_default=1 domain=example.org

  ## Setup theme
  #above# drush -y en garland
  export SITE_CONFIG_DIR
  drush -y -u "$ADMIN_USER" scr "$SITE_CONFIG_DIR/install-theme.php"

  ## Based on the block info, CRM_Core_Block::CREATE_NEW and CRM_Core_Block::ADD should be enabled by default, but they aren't.
  ## "drush -y cc all" and "drush -y cc block" do *NOT* solve the problem. But this does:
  drush php-eval -u "$ADMIN_USER" 'module_load_include("inc","block","block.admin"); block_admin_display();'

  ## Setup welcome page
  drush -y scr "$SITE_CONFIG_DIR/install-welcome.php"
  drush -y vset site_frontpage "welcome"

  ## Setup login_destination
  #above# drush -y en login_destination
  drush -y scr "$SITE_CONFIG_DIR/install-login-destination.php"

  ## Setup userprotect
  #above# drush -y en userprotect
  for perm in "change own e-mail" "change own openid" "change own password" ; do
    drush role-remove-perm "authenticated user" "$perm"
  done

  ## Setup demo user
  drush -y en civicrm_webtest
  drush -y user-create --password="$DEMO_PASS" --mail="$DEMO_EMAIL" "$DEMO_USER"
  drush -y user-add-role civicrm_webtest_user "$DEMO_USER"
  # In Garland, CiviCRM's toolbar looks messy unless you also activate Drupal's "toolbar", so grant "access toolbar"
  # We've activated more components than typical web-test baseline, so grant rights to those components.
  for perm in 'access toolbar' \
    'administer CiviCase' 'access all cases and activities' 'access my cases and activities' 'add cases' 'delete in CiviCase' \
    'administer CiviCampaign' 'manage campaign' \
    'reserve campaign contacts' 'release campaign contacts' 'interview campaign contacts' 'gotv campaign contacts' 'sign CiviCRM Petition'
  do
    drush -y role-add-perm civicrm_webtest_user "$perm"
  done

  ## Setup CiviVolunteer
  drush -y cvapi extension.install key=org.civicrm.volunteer
  drush -y role-add-perm 'anonymous user' 'register to volunteer'

  ## Setup CiviCRM dashboards
  INSTALL_DASHBOARD_USERS="$ADMIN_USER;$DEMO_USER" drush scr "$SITE_CONFIG_DIR/install-dashboard.php"

popd >> /dev/null