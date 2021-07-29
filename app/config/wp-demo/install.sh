#!/bin/bash

## install.sh -- Create config files and databases; fill the databases

## Transition: Old builds don't have "web/" folder. New builds do.
## TODO: Simplify sometime after Dec 2019
[ -d "$WEB_ROOT/web" ] && CMS_ROOT="$WEB_ROOT/web"

###############################################################################
## Create virtual-host and databases

amp_install

###############################################################################
## Setup WordPress (config files, database tables)

wp_install

###############################################################################
## Setup CiviCRM (config files, database tables)

CIVI_DOMAIN_NAME="Demonstrators Anonymous"
CIVI_DOMAIN_EMAIL="\"Demonstrators Anonymous\" <info@example.org>"
CIVI_CORE="${CMS_ROOT}/wp-content/plugins/civicrm/civicrm"

if [[ "$CIVI_VERSION" =~ ^4.[0123456](\.([0-9]|alpha|beta)+)?$ ]] ; then
  CIVI_SETTINGS="${CMS_ROOT}/wp-content/plugins/civicrm/civicrm.settings.php"
  CIVI_FILES="${CMS_ROOT}/wp-content/plugins/files/civicrm"
  CIVI_EXT_DIR="${CMS_ROOT}/wp-content/plugins/files/civicrm/ext"
  CIVI_EXT_URL="${CMS_URL}/wp-content/plugins/files/civicrm/ext"
else
  CIVI_SETTINGS="${CMS_ROOT}/wp-content/uploads/civicrm/civicrm.settings.php"
  CIVI_FILES="${CMS_ROOT}/wp-content/uploads/civicrm"
  ## civicrm-core v4.7+ sets default ext dir; for older versions, we'll set our own.
fi
CIVI_TEMPLATEC="${CIVI_FILES}/templates_c"
CIVI_UF="WordPress"

civicrm_install

###############################################################################
## Extra configuration

pushd "$CMS_ROOT" >> /dev/null

## Clear out default content. Load real content.
TZ=$(php --info |grep 'Default timezone' |sed s/' => '/:/ |cut -d':' -f2)
wp option set timezone_string $TZ
wp post delete 1
wp post delete 2
wp rewrite structure '/%postname%/'
wp rewrite flush --hard
wp plugin install wordpress-importer --activate
wp import "$SITE_CONFIG_DIR/civicrm-wordpress.xml" --authors=create
wp search-replace 'http://civicrm-wordpress.ex' "$SITE_URL"
wp theme install twentythirteen --activate
wp eval '$home = get_page_by_title("Welcome to CiviCRM with WordPress"); update_option("page_on_front", $home->ID); update_option("show_on_front", "page");'

wp plugin activate civicrm
wp eval '$c=[civi_wp(), "add_wpload_setting"]; if (is_callable($c)) $c();' ## Temporary workaround, init wpLoadPh
wp plugin activate civicrm-demo-wp
wp plugin install civicrm-admin-utilities
wp plugin install gutenberg
wp plugin install classic-editor --activate

civicrm_apply_demo_defaults
cv ev 'if(is_callable(array("CRM_Core_BAO_CMSUser","synchronize"))){CRM_Core_BAO_CMSUser::synchronize(FALSE);}else{CRM_Utils_System::synchronizeUsers();}'

wp role create civicrm_admin 'CiviCRM Administrator'
wp cap add civicrm_admin \
  read \
  level_0
wp cap add civicrm_admin \
  access_ajax_api \
  access_all_cases_and_activities \
  access_all_custom_data \
  access_civicontribute \
  access_civicrm \
  access_civievent \
  access_civigrant \
  access_civimail \
  access_civimail_subscribe_unsubscribe_pages \
  access_civimember \
  access_civipledge \
  access_civireport \
  access_contact_dashboard \
  access_contact_reference_fields \
  access_deleted_contacts \
  access_my_cases_and_activities \
  access_report_criteria \
  access_uploaded_files \
  add_cases \
  add_contacts \
  administer_civicampaign \
  administer_civicase \
  administer_civicrm \
  administer_dedupe_rules \
  administer_reports \
  administer_reserved_groups \
  administer_reserved_reports \
  administer_reserved_tags \
  administer_tagsets \
  create_manual_batch \
  delete_activities \
  delete_all_manual_batches \
  delete_contacts \
  delete_in_civicase \
  delete_in_civicontribute \
  delete_in_civievent \
  delete_in_civigrant \
  delete_in_civimail \
  delete_in_civimember \
  delete_in_civipledge \
  delete_own_manual_batches \
  edit_all_contacts \
  edit_all_events \
  edit_all_manual_batches \
  edit_contributions \
  edit_event_participants \
  edit_grants \
  edit_groups \
  edit_memberships \
  edit_own_manual_batches \
  edit_pledges \
  export_all_manual_batches \
  export_own_manual_batches \
  gotv_campaign_contacts \
  import_contacts \
  interview_campaign_contacts \
  make_online_contributions \
  manage_campaign \
  merge_duplicate_contacts \
  profile_create \
  profile_edit \
  profile_listings \
  profile_listings_and_forms \
  profile_view \
  register_for_events \
  release_campaign_contacts \
  reserve_campaign_contacts \
  sign_civicrm_petition \
  translate_civicrm \
  view_all_activities \
  view_all_contacts \
  view_all_manual_batches \
  view_all_notes \
  view_debug_output \
  view_event_info \
  view_event_participants \
  view_own_manual_batches \
  view_public_civimail_content

wp user create "$DEMO_USER" "$DEMO_EMAIL" --role=civicrm_admin --user_pass="$DEMO_PASS"
## Ceate anonymous user role
wp eval '$c=[civi_wp()->users->set_wp_user_capabilities()];if (is_callable($c)) $c();'
## Force basepage
wp eval '$c=[civi_wp()->basepage->create_wp_basepage()];if (is_callable($c)) $c();'

## Setup demo extensions
cv en --ignore-missing $CIVI_DEMO_EXTS
if [[ "$CIVI_DEMO_EXTS" =~ volunteer ]]; then
  wp cap add civicrm_admin \
    register_to_volunteer \
    log_own_hours \
    create_volunteer_projects \
    edit_own_volunteer_projects \
    edit_all_volunteer_projects \
    delete_all_volunteer_projects \
    delete_own_volunteer_projects \
    edit_volunteer_registration_profiles \
    edit_volunteer_project_relationships
fi

## Demo sites always disable email and often disable cron
wp civicrm api StatusPreference.create ignore_severity=critical name=checkOutboundMail
wp civicrm api StatusPreference.create ignore_severity=critical name=checkLastCron

# Disable WP fatal error handler as it gets in the way of debugging.
wp config set WP_DISABLE_FATAL_ERROR_HANDLER true --raw

popd >> /dev/null
