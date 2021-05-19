#!/bin/bash

## install.sh -- Create config files and databases; fill the databases

## Transition: Old builds don't have "web/" folder. New builds do.
## TODO: Simplify sometime after Dec 2019
[ -d "$WEB_ROOT/web" ] && CMS_ROOT="$WEB_ROOT/web"

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
CIVI_CORE="${CMS_ROOT}/sites/all/modules/civicrm"
CIVI_SETTINGS="${CMS_ROOT}/sites/${DRUPAL_SITE_DIR}/civicrm.settings.php"
CIVI_FILES="${CMS_ROOT}/sites/${DRUPAL_SITE_DIR}/files/civicrm"
CIVI_TEMPLATEC="${CIVI_FILES}/templates_c"

CIVI_UF="Drupal"

## civicrm-core v4.7+ sets default ext dir; for older versions, we'll set our own.
if [[ "$CIVI_VERSION" =~ ^4.[0123456](\.([0-9]|alpha|beta)+)?$ ]] ; then
  CIVI_EXT_DIR="${CMS_ROOT}/sites/${DRUPAL_SITE_DIR}/ext"
  CIVI_EXT_URL="${CMS_URL}/sites/${DRUPAL_SITE_DIR}/ext"
fi

civicrm_install

###############################################################################
## Extra configuration
pushd "${CMS_ROOT}/sites/${DRUPAL_SITE_DIR}" >> /dev/null

  drush -y updatedb
  drush -y en civicrm toolbar locale garland login_destination userprotect
  ## disable annoying/unneeded modules
  drush -y dis overlay

  ## Setup CiviCRM
  echo '{"enable_components":["CiviEvent","CiviContribute","CiviMember","CiviMail","CiviReport","CiviPledge","CiviCase","CiviCampaign","CiviGrant"]}' \
    | drush cvapi setting.create --in=json
  ## Note: CiviGrant disabled by default. If you enable, update the permissions as well.
  civicrm_apply_demo_defaults
  cv ev 'if(is_callable(array("CRM_Core_BAO_CMSUser","synchronize"))){CRM_Core_BAO_CMSUser::synchronize(FALSE);}else{CRM_Utils_System::synchronizeUsers();}'

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
  drush scr "$PRJDIR/src/drush/perm.php" <<EOPERM
    role "authenticated user"
    remove "change own e-mail"
    remove "change own openid"
    remove "change own password"
EOPERM

  ## Setup demo user
  drush -y en civicrm_webtest
  drush -y user-create --password="$DEMO_PASS" --mail="$DEMO_EMAIL" "$DEMO_USER"
  drush -y user-add-role civicrm_webtest_user "$DEMO_USER"
  # In Garland, CiviCRM's toolbar looks messy unless you also activate Drupal's "toolbar", so grant "access toolbar"
  # We've activated more components than typical web-test baseline, so grant rights to those components.
  drush scr "$PRJDIR/src/drush/perm.php" <<EOPERM
    role 'civicrm_webtest_user'
    add 'access toolbar'
    add 'administer CiviCase'
    add 'access all cases and activities'
    add 'access my cases and activities'
    add 'add cases'
    add 'delete in CiviCase'
    add 'administer CiviCampaign'
    add 'manage campaign'
    add 'reserve campaign contacts'
    add 'release campaign contacts'
    add 'interview campaign contacts'
    add 'gotv campaign contacts'
    add 'sign CiviCRM Petition'
    add 'access CiviGrant'
    add 'edit grants'
    add 'delete in CiviGrant'
EOPERM
  ## Note: If you enable CiviGrant, the grant 'access CiviGrant', 'edit grants', 'delete in CiviGrant'

  ## Setup demo extensions
  cv en --ignore-missing $CIVI_DEMO_EXTS
  if [[ "$CIVI_DEMO_EXTS" =~ volunteer ]]; then
    drush scr "$PRJDIR/src/drush/perm.php" <<EOPERM
      role 'anonymous user'
      role 'authenticated user'
      add 'register to volunteer'
EOPERM
  fi

  ## Demo sites always disable email and often disable cron
  drush cvapi StatusPreference.create ignore_severity=critical name=checkOutboundMail
  drush cvapi StatusPreference.create ignore_severity=critical name=checkLastCron

  ## Setup CiviCRM dashboards
  INSTALL_DASHBOARD_USERS="$ADMIN_USER;$DEMO_USER" drush scr "$SITE_CONFIG_DIR/install-dashboard.php"

popd >> /dev/null
