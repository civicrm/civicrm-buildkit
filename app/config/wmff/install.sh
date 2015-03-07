#!/bin/bash

## install.sh -- Create config files and databases; fill the databases

## Drupal is actually in a subdir of the main source tree
CMS_ROOT="$WEB_ROOT/drupal"

###############################################################################
## Create virtual-host and databases

amp_install

###############################################################################
## Setup Drupal (config files, database tables)

drupal_install

###############################################################################
## Setup CiviCRM (config files, database tables)

CIVI_DOMAIN_NAME="Demonstrators Anonymous"
CIVI_DOMAIN_EMAIL="\"Demonstrators Anonymous\" <info@example.org>"
CIVI_CORE="${WEB_ROOT}/sites/all/modules/civicrm"
CIVI_SETTINGS="${WEB_ROOT}/sites/default/civicrm.settings.php"
CIVI_FILES="${WEB_ROOT}/sites/default/files/civicrm"
CIVI_TEMPLATEC="${CIVI_FILES}/templates_c"
CIVI_UF="Drupal"

civicrm_install

###############################################################################
## Extra configuration
pushd "$CMS_ROOT"
drush -y en \
  civicrm \
  toolbar \
  garland \
  contribution_audit \
  contribution_tracking \
  environment_indicator \
  exchange_rates \
  ganglia_reporter \
  globalcollect_audit \
  large_donation \
  log_audit \
  offline2civicrm \
  paypal_audit \
  queue2civicrm \
  recurring \
  recurring_globalcollect \
  syslog \
  thank_you \
  wmf_audit \
  wmf_campaigns \
  wmf_civicrm \
  wmf_common \
  wmf_communication \
  wmf_contribution_search \
  wmf_fredge_qc \
  wmf_logging \
  wmf_refund_qc \
  wmf_reports \
  wmf_test_settings \
  wmf_unsubscribe \
  wmf_unsubscribe_qc \
  wmf_zendesk_reports \
  worldpay_audit

drush -y updatedb

## Setup theme
#above# drush -y en garland
export SITE_CONFIG_DIR
drush -y -u "$ADMIN_USER" scr "$SITE_CONFIG_DIR/install-theme.php"

## Based on the block info, CRM_Core_Block::CREATE_NEW and CRM_Core_Block::ADD should be enabled by default, but they aren't.
## "drush -y cc all" and "drush -y cc block" do *NOT* solve the problem. But this does:
drush php-eval -u "$ADMIN_USER" 'module_load_include("inc","block","block.admin"); block_admin_display();'

## Setup demo user
drush -y user-create --password="$DEMO_PASS" --mail="$DEMO_EMAIL" "$DEMO_USER"
#drush -y user-add-role civicrm_webtest_user "$DEMO_USER"
# In Garland, CiviCRM's toolbar looks messy unless you also activate Drupal's "toolbar", so grant "access toolbar"
# We've activated more components than typical web-test baseline, so grant rights to those components.
#for perm in 'access toolbar'
#do
#  drush -y role-add-perm civicrm_webtest_user "$perm"
#done
popd
