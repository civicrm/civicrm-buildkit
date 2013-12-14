#!/bin/bash

## Setup a CiviCRM-WordPress demo site. (For use with "civi-install")
##
## usage: civi-install wp-demo <url> <db-name>
## usage: civi-install wp-demo http://localhost:8181 civiwp

## Drop/create MySQL DB & user
mysql_dropcreate

## (Re)Create WP config files, tables, and data dirs
wp_install

## (Re)create CiviCRM config files, tables, and data dirs
civicrm_install

## Apply demo site customizations
pushd "$WEB_ROOT" >> /dev/null
  ## Clear out default content. Load real content.
  wp post delete 1
  wp post delete 2
  wp rewrite structure '/%postname%/'
  wp rewrite flush --hard
  wp plugin install wordpress-importer --activate
  wp import ../app/config/civicrm-wordpress.xml --authors=create
  wp search-replace 'http://civicrm-wordpress.ex' "$SITE_URL"
  wp eval '$home = get_page_by_title("Welcome to CiviCRM with WordPress"); update_option("page_on_front", $home->ID); update_option("show_on_front", "page");'

  wp plugin activate civicrm

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
popd >> /dev/null
