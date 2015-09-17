<?php
civicrm_initialize();

// -----------------------------
// Get a list of users to update
if (! getenv('INSTALL_DASHBOARD_USERS')) {
  throw new RuntimeException('Missing environment variable: INSTALL_DASHBOARD_USERS');
}
$users = explode(';', getenv('INSTALL_DASHBOARD_USERS'));
CRM_Core_BAO_CMSUser::synchronize(FALSE);

// ------------------------------
// Get list of available dashlets
$dashletTypeResult = civicrm_api3('Dashboard', 'get', array(
  'domain_id' => CRM_Core_Config::domainID()
));
$dashletTypes = CRM_Utils_Array::index(array('name'), $dashletTypeResult['values']);

// ---------------------------------------
// Build list of specific dashlets to add
$dashlets = array(
  // -----------
  // Left column
  // -----------
  array(
    'dashboard_id' => $dashletTypes['report/25']['id'], // Event Income Summary
    'column_no' => 0,
    'is_minimized' => 0,
    'is_fullscreen' => 1,
    'weight' => 1,
  ),
  array(
    'dashboard_id' => $dashletTypes['report/13']['id'], // Top Donors
    'column_no' => 0,
    'is_minimized' => 0,
    'is_fullscreen' => 1,
    'weight' => 3,
  ),
  array(
    'dashboard_id' => $dashletTypes['report/6']['id'], // Donor Summary
    'column_no' => 0,
    'is_minimized' => 0,
    'is_fullscreen' => 1,
    'weight' => 4,
  ),
  // ------------
  // Right column
  // ------------
  array(
    'dashboard_id' => $dashletTypes['activity']['id'],
    'column_no' => 1,
    'is_minimized' => 0,
    'is_fullscreen' => 1,
    'weight' => 10,
  ),
  array(
    'dashboard_id' => $dashletTypes['myCases']['id'],
    'column_no' => 1,
    'is_minimized' => 0,
    'is_fullscreen' => 1,
    'weight' => 11,
  ),
  array(
    'dashboard_id' => $dashletTypes['report/20']['id'], // Membership Summary
    'column_no' => 1,
    'is_minimized' => 0,
    'is_fullscreen' => 1,
    'weight' => 12,
  ),
);

// -------------------
// Insert the dashlets
$tx = new CRM_Core_Transaction();
try {
  foreach ($users as $user) {
    foreach ($dashlets as $dashlet) {
      $dashlet['contact_id'] = "@user:$user";
      $dashlet['is_active'] = 1;
      $dashlet['debug'] = 1;
      civicrm_api3('dashboard_contact', 'create', $dashlet);
    }
  }
} catch (CiviCRM_API3_Exception $e) {
  $tx->rollback();
  echo get_class($e) . ' -- ' . $e->getMessage() . "\n";
  echo $e->getTraceAsString() . "\n";
  print_r($e->getExtraParams());
}
