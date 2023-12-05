#!/usr/bin/env bash

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

civicrm_install_transitional

###############################################################################
## Extra configuration
pushd "${CMS_ROOT}/sites/${DRUPAL_SITE_DIR}" >> /dev/null

  drush -y updatedb
  drush -y en civicrm toolbar locale garland
  ## disable annoying/unneeded modules
  drush -y dis overlay

  cv ev 'if(is_callable(array("CRM_Core_BAO_CMSUser","synchronize"))){CRM_Core_BAO_CMSUser::synchronize(FALSE);}else{CRM_Utils_System::synchronizeUsers();}'

  ## Setup theme
  #above# drush -y en garland
  export SITE_CONFIG_DIR
  drush -y -u "$ADMIN_USER" scr "$SITE_CONFIG_DIR/install-theme.php"

  ## Based on the block info, CRM_Core_Block::CREATE_NEW and CRM_Core_Block::ADD should be enabled by default, but they aren't.
  ## "drush -y cc all" and "drush -y cc block" do *NOT* solve the problem. But this does:
  drush php-eval -u "$ADMIN_USER" 'module_load_include("inc","block","block.admin"); block_admin_display();'

  ## Setup demo user
  drush -y en civicrm_webtest
  drush -y user-create --password="$DEMO_PASS" --mail="$DEMO_EMAIL" "$DEMO_USER"
  drush -y user-add-role civicrm_webtest_user "$DEMO_USER"
  # In Garland, CiviCRM's toolbar looks messy unless you also activate Drupal's "toolbar", so grant "access toolbar"
  # We've activated more components than typical web-test baseline, so grant rights to those components.
  for perm in 'access toolbar'
  do
    drush -y role-add-perm civicrm_webtest_user "$perm"
  done

  # cv en civirules

popd >> /dev/null
