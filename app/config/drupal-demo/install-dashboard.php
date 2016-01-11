<?php
civicrm_initialize();

// -----------------------------
// Get a list of users to update
if (!getenv('INSTALL_DASHBOARD_USERS')) {
  throw new RuntimeException('Missing environment variable: INSTALL_DASHBOARD_USERS');
}
$users = explode(';', getenv('INSTALL_DASHBOARD_USERS'));

// WISHLIST: CMSUser::synchronize probably merits an API but lacks test coverage.
if (is_callable(array('CRM_Core_BAO_CMSUser', 'synchronize'))) {
  CRM_Core_BAO_CMSUser::synchronize(FALSE); // 4.6 and earlier
}
else {
  CRM_Utils_System::synchronizeUsers(); // v4.7+
}

// ------------------------------
// Get list of available dashlets
$reportInstanceResult = civicrm_api3('ReportInstance', 'get', array(
  'option.limit' => 0,
));
$reportInstanceNames = CRM_Utils_Array::index(array('report_id'), $reportInstanceResult['values']);
$dashletTypeResult = civicrm_api3('Dashboard', 'get', array(
  'domain_id' => CRM_Core_Config::domainID(),
));
$dashletTypes = CRM_Utils_Array::index(array('name'), $dashletTypeResult['values']);

// ---------------------------------------
// Build list of specific dashlets to add
$dashlets = array(
  // -----------
  // Left column
  // -----------
  array(
    // Event Income Summary
    'dashboard_id' => $dashletTypes['report/' . $reportInstanceNames['event/summary']['id']]['id'],
    'column_no' => 0,
    'is_minimized' => 0,
    'is_fullscreen' => 1,
    'weight' => 1,
  ),
  array(
    // Top Donors
    'dashboard_id' => $dashletTypes['report/' . $reportInstanceNames['contribute/topDonor']['id']]['id'],
    'column_no' => 0,
    'is_minimized' => 0,
    'is_fullscreen' => 1,
    'weight' => 3,
  ),
  array(
    // Donor Summary
    'dashboard_id' => $dashletTypes['report/' . $reportInstanceNames['contribute/summary']['id']]['id'],
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
    // Membership Summary
    'dashboard_id' => $dashletTypes['report/' . $reportInstanceNames['member/summary']['id']]['id'],
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
}
catch (CiviCRM_API3_Exception $e) {
  $tx->rollback();
  echo get_class($e) . ' -- ' . $e->getMessage() . "\n";
  echo $e->getTraceAsString() . "\n";
  print_r($e->getExtraParams());
}
