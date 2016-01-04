#!/bin/bash

## install.sh -- Create config files and databases; fill the databases

###############################################################################
## Create virtual-host and databases

amp_install

###############################################################################
## Setup Drupal (config files, database tables)

drupal8_install

###############################################################################
## Setup CiviCRM (config files, database tables)

DRUPAL_SITE_DIR=$(_drupal_multisite_dir "$CMS_URL" "$SITE_ID")
CIVI_DOMAIN_NAME="Demonstrators Anonymous"
CIVI_DOMAIN_EMAIL="\"Demonstrators Anonymous\" <info@example.org>"
CIVI_CORE="${WEB_ROOT}/libraries/civicrm"
CIVI_SETTINGS="${WEB_ROOT}/sites/${DRUPAL_SITE_DIR}/civicrm.settings.php"
CIVI_FILES="${WEB_ROOT}/sites/${DRUPAL_SITE_DIR}/files/civicrm"
CIVI_TEMPLATEC="${CIVI_FILES}/templates_c"
CIVI_UF="Drupal8"

## civicrm-core v4.7+ sets default ext dir; for older versions, we'll set our own.
if [[ "$CIVI_VERSION" =~ ^4.[0123456](\.([0-9]|alpha|beta)+)?$ ]] ; then
  CIVI_EXT_DIR="${WEB_ROOT}/sites/${DRUPAL_SITE_DIR}/ext"
  CIVI_EXT_URL="${CMS_URL}/sites/${DRUPAL_SITE_DIR}/ext"
fi

# these steps should be happening because of the make file but....
# perhaps because they are not on https://www.drupal.org/project/drupalorg_whitelist ?
mkdir -p "${WEB_ROOT}/libraries/"
cd "${WEB_ROOT}/libraries/"
if [[ ! -e 'civicrm' ]]; then
  git clone https://github.com/civicrm/civicrm-core.git
fi
cd civicrm
if [[ ! -e 'packages' ]]; then
  git clone https://github.com/civicrm/civicrm-packages.git
fi

cd "${WEB_ROOT}/modules/"
if [[ ! -e 'civicrm' ]]; then
  git clone https://github.com/civicrm/civicrm-drupal.git -b 8.x-${CIVI_VERSION} civicrm
fi

civicrm_install

###############################################################################
## Extra configuration
pushd "${WEB_ROOT}/sites/${DRUPAL_SITE_DIR}" >> /dev/null

  drush -y updatedb
  drush -y en civicrm

  ## make sure drush functions are loaded
  drush cc drush -y

  ## Setup CiviCRM
  echo '{"enable_components":["CiviEvent","CiviContribute","CiviMember","CiviMail","CiviReport","CiviPledge","CiviCase","CiviCampaign"]}' \
    | drush cvapi setting.create --in=json
  drush cvapi setting.create versionCheck=0 debug=1
  drush cvapi MailSettings.create id=1 is_default=1 domain=example.org debug=1

  ## Setup theme
  #above# drush -y en garland
  export SITE_CONFIG_DIR
  # (not d8 ready) drush -y -u "$ADMIN_USER" scr "$SITE_CONFIG_DIR/install-theme.php"

  ## Based on the block info, CRM_Core_Block::CREATE_NEW and CRM_Core_Block::ADD should be enabled by default, but they aren't.
  ## "drush -y cc all" and "drush -y cc block" do *NOT* solve the problem. But this does:
  ## doesn't work on d8
  ## drush php-eval -u "$ADMIN_USER" 'module_load_include("inc","block","block.admin"); block_admin_display();'

  ## Setup welcome page
  #drush -y scr "$SITE_CONFIG_DIR/install-welcome.php"
  # vset doesn't work in d8 drush -y vset site_frontpage "welcome"

  ## Setup login_destination
  #above# drush -y en login_destination
  # doesn't work in d8 drush -y scr "$SITE_CONFIG_DIR/install-login-destination.php"

  ## Setup userprotect
  drush -y dl userprotect
  drush -y en userprotect
  drush -y rmp authenticated userprotect.account.edit
  drush -y rmp authenticated userprotect.mail.edit
  drush -y rmp authenticated userprotect.pass.edit

  ## Setup demo user
  # drush -y en civicrm_webtest
  drush -y role-create 'civicrm webtest user'
  drush -y user-create --password="$DEMO_PASS" --mail="$DEMO_EMAIL" "$DEMO_USER"
  drush -y user-add-role  'civicrm webtest user' "$DEMO_USER"
  drush -y rap 'civicrm webtest user' 'delete activities'
  drush -y rap 'civicrm webtest user' 'access AJAX API'
  drush -y rap 'civicrm webtest user' 'access CiviCRM'
  drush -y rap 'civicrm webtest user' 'access Contact Dashboard'
  drush -y rap 'civicrm webtest user' 'access all custom data'
  drush -y rap 'civicrm webtest user' 'access contact reference fields'
  drush -y rap 'civicrm webtest user' 'access deleted contacts'
  drush -y rap 'civicrm webtest user' 'access uploaded files'
  drush -y rap 'civicrm webtest user' 'add contacts'
  drush -y rap 'civicrm webtest user' 'administer CiviCRM'
  drush -y rap 'civicrm webtest user' 'administer Tagsets'
  drush -y rap 'civicrm webtest user' 'administer dedupe rules'
  drush -y rap 'civicrm webtest user' 'administer payment processors'
  drush -y rap 'civicrm webtest user' 'administer reserved groups'
  drush -y rap 'civicrm webtest user' 'administer reserved tags'
  drush -y rap 'civicrm webtest user' 'create manual batch'
  drush -y rap 'civicrm webtest user' 'delete all manual batches'
  drush -y rap 'civicrm webtest user' 'delete contacts'
  drush -y rap 'civicrm webtest user' 'delete own manual batches'
  drush -y rap 'civicrm webtest user' 'edit all contacts'
  drush -y rap 'civicrm webtest user' 'edit all manual batches'
  drush -y rap 'civicrm webtest user' 'edit groups'
  drush -y rap 'civicrm webtest user' 'edit message templates'
  drush -y rap 'civicrm webtest user' 'edit my contact'
  drush -y rap 'civicrm webtest user' 'edit own manual batches'
  drush -y rap 'civicrm webtest user' 'export all manual batches'
  drush -y rap 'civicrm webtest user' 'export own manual batches'
  drush -y rap 'civicrm webtest user' 'import contacts'
  drush -y rap 'civicrm webtest user' 'import contacts'
  drush -y rap 'civicrm webtest user' 'merge duplicate contacts'
  drush -y rap 'civicrm webtest user' 'profile create'
  drush -y rap 'civicrm webtest user' 'profile edit'
  drush -y rap 'civicrm webtest user' 'profile listings'
  drush -y rap 'civicrm webtest user' 'profile listings and forms'
  drush -y rap 'civicrm webtest user' 'profile view'
  drush -y rap 'civicrm webtest user' 'skip IDS check'
  drush -y rap 'civicrm webtest user' 'translate CiviCRM'
  drush -y rap 'civicrm webtest user' 'view all activities'
  drush -y rap 'civicrm webtest user' 'view all contacts'
  drush -y rap 'civicrm webtest user' 'view all manual batches'
  drush -y rap 'civicrm webtest user' 'view all notes'
  drush -y rap 'civicrm webtest user' 'view debug output'
  drush -y rap 'civicrm webtest user' 'view my contact'
  drush -y rap 'civicrm webtest user' 'view my invoices'
  drush -y rap 'civicrm webtest user' 'view own manual batches'
  drush -y rap 'civicrm webtest user' 'access CiviContribute'
  drush -y rap 'civicrm webtest user' 'delete in CiviContribute'
  drush -y rap 'civicrm webtest user' 'edit contributions'
  drush -y rap 'civicrm webtest user' 'make online contributions'
  drush -y rap 'civicrm webtest user' 'access CiviEvent'
  drush -y rap 'civicrm webtest user' 'delete in CiviEvent'
  drush -y rap 'civicrm webtest user' 'edit all events'
  drush -y rap 'civicrm webtest user' 'edit event participants'
  drush -y rap 'civicrm webtest user' 'manage event profiles'
  drush -y rap 'civicrm webtest user' 'register for events'
  drush -y rap 'civicrm webtest user' 'view event info'
  drush -y rap 'civicrm webtest user' 'view event participants'
  drush -y rap 'civicrm webtest user' 'access CiviMail'
  drush -y rap 'civicrm webtest user' 'access CiviMail subscribe/unsubscribe pages'
  drush -y rap 'civicrm webtest user' 'delete in CiviMail'
  drush -y rap 'civicrm webtest user' 'view public CiviMail content'
  drush -y rap 'civicrm webtest user' 'access CiviMember'
  drush -y rap 'civicrm webtest user' 'delete in CiviMember'
  drush -y rap 'civicrm webtest user' 'edit memberships'
  drush -y rap 'civicrm webtest user' 'access CiviPledge'
  drush -y rap 'civicrm webtest user' 'delete in CiviPledge'
  drush -y rap 'civicrm webtest user' 'edit pledges'
  drush -y rap 'civicrm webtest user' 'access CiviReport'
  drush -y rap 'civicrm webtest user' 'access Report Criteria'
  drush -y rap 'civicrm webtest user' 'administer Reports'
  drush -y rap 'civicrm webtest user' 'administer reserved reports'
  # In Garland, CiviCRM's toolbar looks messy unless you also activate Drupal's "toolbar", so grant "access toolbar"
  # We've activated more components than typical web-test baseline, so grant rights to those components.
  #drush scr "$PRJDIR/src/drush/perm.php" <<EOPERM
  #  role 'civicrm_webtest_user'
  #  add 'access toolbar'
  #  add 'administer CiviCase'
  #  add 'access all cases and activities'
  #  add 'access my cases and activities'
  #  add 'add cases'
  #  add 'delete in CiviCase'
  #  add 'administer CiviCampaign'
  #  add 'manage campaign'
  #  add 'reserve campaign contacts'
  #  add 'release campaign contacts'
  #  add 'interview campaign contacts'
  #  add 'gotv campaign contacts'
  #  add 'sign CiviCRM Petition'
#EOPERM

  ## Setup CiviVolunteer
  drush -y cvapi extension.install key=org.civicrm.volunteer debug=1
  # drush scr "$PRJDIR/src/drush/perm.php" <<EOPERM
  #  role 'anonymous user'
    #d8 can't find role authenticated user
    #role 'authenticated user'
  #  add 'register to volunteer'
#EOPERM

 # drush -y -u "$ADMIN_USER" cvapi extension.install key=eu.tttp.civisualize debug=1
 # drush -y -u "$ADMIN_USER" cvapi extension.install key=org.civicrm.module.cividiscount debug=1

  ## Setup CiviCRM dashboards
 # INSTALL_DASHBOARD_USERS="$ADMIN_USER;$DEMO_USER" drush scr "$SITE_CONFIG_DIR/install-dashboard.php"

popd >> /dev/null
