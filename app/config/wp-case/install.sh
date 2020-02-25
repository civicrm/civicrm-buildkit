#!/bin/bash

## install.sh -- Create config files and databases; fill the databases

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
CIVI_CORE="${WEB_ROOT}/wp-content/plugins/civicrm/civicrm"
CIVI_SETTINGS="${WEB_ROOT}/wp-content/uploads/civicrm/civicrm.settings.php"
CIVI_FILES="${WEB_ROOT}/wp-content/uploads/civicrm"
CIVI_TEMPLATEC="${CIVI_FILES}/templates_c"
CIVI_UF="WordPress"

civicrm_install

###############################################################################
## Extra configuration

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
wp eval '$c=[civi_wp(), "add_wpload_setting"]; if (is_callable($c)) $c();' ## Temporary workaround, init wpLoadPhp
wp plugin activate civicrm-demo-wp

echo '{"enable_components":["CiviMail","CiviReport","CiviCase"]}' | cv api setting.create --in=json
civicrm_apply_demo_defaults
cv ev 'if(is_callable(array("CRM_Core_BAO_CMSUser","synchronize"))){CRM_Core_BAO_CMSUser::synchronize(FALSE);}else{CRM_Utils_System::synchronizeUsers();}'

## Install Shoreditch and CiviCase
cv en shoreditch styleguide civicase
cv api setting.create customCSSURL='[civicrm.root]/ext/shoreditch/css/custom-civicrm.css'
cv scr --user="$ADMIN_USER" "$PRJDIR/src/create-civicase-examples.php"

## Setup permissions
wp role create civicrm_admin 'CiviCRM Administrator'
wp cap add civicrm_admin \
  read \
  level_0
wp cap add civicrm_admin \
  access_ajax_api \
  access_all_cases_and_activities \
  access_all_custom_data \
  access_civicrm \
  access_civimail \
  access_civimail_subscribe/unsubscribe_pages \
  access_civireport \
  access_contact_dashboard \
  access_contact_reference_fields \
  access_deleted_contacts \
  access_my_cases_and_activities \
  access_report_criteria \
  access_toolbar \
  access_uploaded_files \
  add_cases \
  add_contacts \
  administer_civicase \
  administer_civicrm \
  administer_dedupe_rules \
  administer_payment_processors \
  administer_reports \
  administer_tagsets \
  delete_activities \
  delete_contacts \
  delete_in_civicase \
  delete_in_civimail \
  edit_all_contacts \
  edit_groups \
  edit_message_templates \
  edit_my_contact \
  import_contacts \
  manage_tags \
  merge_duplicate_contacts \
  profile_create \
  profile_edit \
  profile_listings \
  profile_listings_and_forms \
  profile_view \
  translate_civicrm \
  view_all_activities \
  view_all_contacts \
  view_all_notes \
  view_my_contact \
  view_public_civimail_content

wp user create "$DEMO_USER" "$DEMO_EMAIL" --role=civicrm_admin --user_pass="$DEMO_PASS"

## Ceate anonymous user role
wp eval '$c=[civi_wp()->users->set_wp_user_capabilities()];if (is_callable($c)) $c();'
## Force basepage
wp eval '$c=[civi_wp()->basepage->create_wp_basepage()];if (is_callable($c)) $c();'
