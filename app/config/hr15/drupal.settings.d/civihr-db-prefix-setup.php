<?php

// Get CIVICRM settings
if (isset($civibuild['CMS_ROOT']) && file_exists($civibuild['CMS_ROOT'] .'/sites/default/civicrm.settings.php')) {
    require_once $civibuild['CMS_ROOT'] .'/sites/default/civicrm.settings.php';
}

$civi_settings = parse_url(CIVICRM_DSN);

if (isset($civi_settings) && !empty($civi_settings)) {

    // Try to increase the memory limit
    ini_set('memory_limit', '512M');
    
    // Add the required civi tables, so Drupal will recognize them
    $GLOBALS['databases']['default']['default']['prefix'] = array (
        'civicrm_contact' => trim($civi_settings['path'], '/') . '.',
        'civicrm_relationship' => trim($civi_settings['path'], '/') . '.',
        'civicrm_address' => trim($civi_settings['path'], '/') . '.',
        'civicrm_activity' => trim($civi_settings['path'], '/') . '.',
        'civicrm_activity_contact' => trim($civi_settings['path'], '/') . '.',
        'civicrm_hrabsence_entitlement' => trim($civi_settings['path'], '/') . '.',
        'civicrm_uf_match' => trim($civi_settings['path'], '/') . '.',
        'civicrm_phone' => trim($civi_settings['path'], '/') . '.',
        'civicrm_email' => trim($civi_settings['path'], '/') . '.',
        'civicrm_value_emergency_contacts_21' => trim($civi_settings['path'], '/') . '.',
    );
    
}