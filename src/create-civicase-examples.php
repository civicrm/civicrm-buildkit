<?php
allowActivityType('housing_support', array('Print PDF Letter', 'Email', 'Case Task'));
allowActivityType('adult_day_care_referral', array('Print PDF Letter', 'Email', 'Case Task'));
addToTimeline('housing_support', array('name' => 'Case Task', 'reference_activity' => 'Open Case', 'reference_offset' => '9', 'reference_select' => 'newest'));
addToTimeline('housing_support', array('name' => 'Case Task', 'reference_activity' => 'Open Case', 'reference_offset' => '10', 'reference_select' => 'newest'));
changeGrouping('Secure temporary housing', 'milestone');
changeGrouping('Long-term housing plan', 'milestone');
changeGrouping('Medical evaluation', 'milestone');
changeGrouping('Mental health evaluation', 'milestone');
changeGrouping('Case Task', 'task');
addExampleTags();
addExampleCases();

function changeGrouping($actType, $grouping) {
  civicrm_api3('OptionValue', 'create', array(
    'option_group_id' => 'activity_type',
    'name' => $actType,
    'grouping' => $grouping,
    'options' => array('match' => array('option_group_id', 'name')),
  ));
}

/**
 * Add more activity-types to a case-type.
 */
function allowActivityType($caseType, $addActTypes) {
  $caseType = civicrm_api3('CaseType', 'getsingle', array('name' => $caseType));
  $actTypes = CRM_Utils_Array::collect('name', $caseType['definition']['activityTypes']);
  $newTypes = array_diff($addActTypes, $actTypes);
  foreach ($newTypes as $newType) {
    $caseType['definition']['activityTypes'][] = array(
      'name' => $newType,
    );
  }
  civicrm_api3('CaseType', 'create', array(
    'id' => $caseType['id'],
    'definition' => $caseType['definition'],
  ));
}

/**
 * Add another entry to the timeline
 */
function addToTimeline($caseType, $timelineEntry) {
  $caseType = civicrm_api3('CaseType', 'getsingle', array('name' => $caseType));

  foreach ($caseType['definition']['activitySets'] as &$actSet) {
    if ($actSet['name'] === 'standard_timeline') {
      $actSet['activityTypes'][] = $timelineEntry;
    }
  }

  civicrm_api3('CaseType', 'create', array(
    'id' => $caseType['id'],
    'definition' => $caseType['definition'],
  ));
}

/**
 * Add tags for cases and activities.
 */
function addExampleTags() {
  $fruit = civicrm_api3('Tag', 'create', array('name' => 'Fruit', 'description' => 'Sweet and nutritious', 'is_tagset' => 1, 'used_for' => array('civicrm_activity', 'civicrm_case')));

  civicrm_api3('Tag', 'create', array('name' => 'Apple', 'description' => 'An apple a day keeps the Windows away', 'color' => '#ec3737', 'parent_id' => $fruit['id']));
  civicrm_api3('Tag', 'create', array('name' => 'Banana', 'description' => 'Going bananas for tagsets', 'color' => '#d5d620', 'parent_id' => $fruit['id']));
  civicrm_api3('Tag', 'create', array('name' => 'Grape', 'description' => 'I heard it through the grapevine', 'color' => '#9044b8', 'parent_id' => $fruit['id']));
  civicrm_api3('Tag', 'create', array('name' => 'Orange', 'description' => 'Orange you glad this isn\'t a pun?', 'color' => '#ff9d2a', 'parent_id' => $fruit['id']));

  civicrm_api3('Tag', 'create', array('name' => 'Edge Case', 'description' => 'Edge Case', 'color' => '#000000', 'used_for' => array('civicrm_case')));

  civicrm_api3('Tag', 'create', array('name' => 'Strenuous', 'description' => 'Strenuous activity', 'color' => '#00ff00', 'used_for' => array('civicrm_activity')));
  civicrm_api3('Tag', 'create', array('name' => 'Leisurely', 'description' => 'Leisurely activity', 'color' => '#006f00', 'used_for' => array('civicrm_activity')));
}

/**
 * Create one case for each individual contact.
 *
 * Randomly add a second or third contact to some cases.
 */
function addExampleCases() {
  $caseTypes = array(
    'housing_support',
    'adult_day_care_referral',
  );
  $exampleTags = array('Apple', 'Banana', 'Grape', 'Orange', 'Edge Case');

  $contacts = civicrm_api3('Contact', 'get', array(
    'contact_type' => 'Individual',
    'is_deceased' => 0,
    'options' => array('limit' => 0),
    'return' => array('id', 'display_name'),
  ));

  foreach ($contacts['values'] as $cid => $contact) {
    $caseType = $caseTypes[$cid % count($caseTypes)];
    $cids = array($cid);
    $names = array();
    // Add additonal contacts to case
    if (mt_rand(0, 10) > 6) {
      $cids = array_unique(array($cid, array_rand($contacts['values'])));
      if (mt_rand(0, 10) > 5) {
        $cids = array_unique(array($cid, array_rand($contacts['values']), array_rand($contacts['values'])));
      }
    }
    foreach ($cids as $c) {
      $names[] = $contacts['values'][$c]['display_name'];
    }
    $age = mt_rand(0, 500);
    $endDate = ($age > 300) ? mt_rand(0, 200) : NULL;
    $case = civicrm_api3('Case', 'create', array(
      'contact_id' => $cids,
      'case_type_id' => $caseType,
      'subject' => substr("This case is in reference to " . implode(' and ', $names), 0, 127) . ".",
      'start_date' => "now - $age day",
      'end_date' => $endDate ? "now - $endDate day" : NULL,
      'status_id' => $endDate ? 'Closed' : 'Open',
    ));
    if ($endDate) {
      civicrm_api3('Activity', 'create', array(
        'case_id' => $case['id'],
        'activity_type_id' => 'Change Case Status',
        'target_contact_id' => $cids,
        'subject' => 'Case status changed from Ongoing to Resolved',
        'activity_date_time' => "now - $endDate day",
        'status_id' => 'Completed',
      ));
      civicrm_api3('Activity', 'get', array(
        'case_id' => $case['id'],
        'status_id' => 'Scheduled',
        'api.Activity.setvalue' => array('field' => 'status_id', 'value' => 2),
      ));
    }
    // Tag some cases
    if (mt_rand(0, 10) > 5) {
      $tag = array_rand($exampleTags);
      civicrm_api3('EntityTag', 'create', array(
        'entity_table' => "civicrm_case",
        'entity_id' => $case['id'],
        'tag_id' => $exampleTags[$tag],
      ));
    }
  }
}
