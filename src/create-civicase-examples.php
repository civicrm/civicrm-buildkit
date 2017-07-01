<?php

addMilestoneActivityType();
updateCaseType('housing_support', array('Print PDF Letter', 'Email', 'Milestone'));
addExampleTags();
addExampleCases();

function addMilestoneActivityType() {
  civicrm_api3('OptionValue', 'create', array(
    'option_group_id' => 'activity_type',
    'label' => 'Milestone',
    'name' => 'Milestone',
    'grouping' => 'milestone',
    'component_id' => 'CiviCase',
    'options' => array('match' => array('option_group_id', 'name')),
  ));
}

/**
 * Add more activity-types to a case-type.
 */
function updateCaseType($caseType, $addActTypes) {
  $housingSupport = civicrm_api3('CaseType', 'getsingle', array('name' => 'housing_support'));
  $actTypes = CRM_Utils_Array::collect('name', $housingSupport['definition']['activityTypes']);
  $newTypes = array_diff($addActTypes, $actTypes);
  foreach ($newTypes as $newType) {
    $housingSupport['definition']['activityTypes'][] = array(
      'name' => $newType,
    );
  }
  civicrm_api3('CaseType', 'create', array(
    'id' => $housingSupport['id'],
    'definition' => $housingSupport['definition'],
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
 * Create one case for each contact (#100..#150).
 */
function addExampleCases() {
  $caseTypes = array(
    'housing_support',
    'adult_day_care_referral',
  );

  for ($i = 100; $i < 150; $i++) {
    $caseType = $caseTypes[$i % count($caseTypes)];
    civicrm_api3('Case', 'create', array(
      'contact_id' => $i,
      'case_type_id' => $caseType,
      'subject' => "The $i subject",
    ));
  }
}
