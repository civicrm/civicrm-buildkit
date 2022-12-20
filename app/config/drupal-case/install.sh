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

civicrm_install_transitional

###############################################################################
## Extra configuration
pushd "${CMS_ROOT}/sites/${DRUPAL_SITE_DIR}" >> /dev/null

  drush -y updatedb
  drush -y en civicrm toolbar locale seven login_destination userprotect
  ## disable annoying/unneeded modules
  drush -y dis overlay

  ## Setup CiviCRM
  echo '{"enable_components":["CiviMail","CiviReport","CiviCase"]}' \
    | drush cvapi setting.create --in=json
  ## Note: CiviGrant disabled by default. If you enable, update the permissions as well.
  civicrm_apply_demo_defaults
  cv ev 'if(is_callable(array("CRM_Core_BAO_CMSUser","synchronize"))){CRM_Core_BAO_CMSUser::synchronize(FALSE);}else{CRM_Utils_System::synchronizeUsers();}'

  ## Setup theme
  #above# drush -y en seven
  export SITE_CONFIG_DIR
  # drush -y -u "$ADMIN_USER" scr "$SITE_CONFIG_DIR/install-theme.php"
  drush -y vset theme_default seven

  ## Install Shoreditch and CiviCase
  cv en shoreditch styleguide civicase
  cv api setting.create customCSSURL='[civicrm.root]/ext/shoreditch/css/custom-civicrm.css'
  cv scr --user="$ADMIN_USER" "$PRJDIR/src/create-civicase-examples.php"

  ## Based on the block info, CRM_Core_Block::CREATE_NEW and CRM_Core_Block::ADD should be enabled by default, but they aren't.
  ## "drush -y cc all" and "drush -y cc block" do *NOT* solve the problem. But this does:
  #drush php-eval -u "$ADMIN_USER" 'module_load_include("inc","block","block.admin"); block_admin_display();'

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
  drush role-create civicase_demo
  drush -y user-create --password="$DEMO_PASS" --mail="$DEMO_EMAIL" "$DEMO_USER"
  drush -y user-add-role civicase_demo "$DEMO_USER"
  drush scr "$PRJDIR/src/drush/perm.php" <<EOPERM
    role 'anonymous user'
    add 'access CiviMail subscribe/unsubscribe pages'
    add 'access all custom data'
    add 'access uploaded files'
    add 'profile create'
    add 'profile view'
EOPERM

  drush scr "$PRJDIR/src/drush/perm.php" <<EOPERM
    role 'civicase_demo'
    add 'access AJAX API'
    add 'access all cases and activities'
    add 'access all custom data'
    add 'access CiviCRM'
    add 'access CiviMail'
    add 'access CiviMail subscribe/unsubscribe pages'
    add 'access CiviReport'
    add 'access Contact Dashboard'
    add 'access contact reference fields'
    add 'access deleted contacts'
    add 'access my cases and activities'
    add 'access Report Criteria'
    add 'access toolbar'
    add 'access uploaded files'
    add 'add cases'
    add 'add contacts'
    add 'administer CiviCase'
    add 'administer CiviCRM'
    add 'administer dedupe rules'
    add 'administer payment processors'
    add 'administer Reports'
    add 'administer Tagsets'
    add 'delete activities'
    add 'delete contacts'
    add 'delete in CiviCase'
    add 'delete in CiviMail'
    add 'edit all contacts'
    add 'edit groups'
    add 'edit message templates'
    add 'edit my contact'
    add 'import contacts'
    add 'manage tags'
    add 'merge duplicate contacts'
    add 'profile create'
    add 'profile edit'
    add 'profile listings'
    add 'profile listings and forms'
    add 'profile view'
    add 'translate CiviCRM'
    add 'view all activities'
    add 'view all contacts'
    add 'view all notes'
    add 'view my contact'
    add 'view public CiviMail content'
EOPERM

popd >> /dev/null
