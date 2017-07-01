<?php

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

$fruit = civicrm_api3('Tag', 'create', array( 'name' => 'Fruit', 'description' => 'Sweet and nutritious', 'is_tagset' => 1, 'used_for' => array('civicrm_activity','civicrm_case')));
civicrm_api3('Tag', 'create', array('name' => 'Apple', 'description' => 'An apple a day keeps the Windows away', 'color' => '#ec3737', 'parent_id' => $fruit['id']));
civicrm_api3('Tag', 'create', array('name' => 'Banana', 'description' => 'Going bananas for tagsets', 'color' => '#d5d620', 'parent_id' => $fruit['id']));
civicrm_api3('Tag', 'create', array('name' => 'Grape', 'description' => 'I heard it through the grapevine', 'color' => '#9044b8', 'parent_id' => $fruit['id']));
civicrm_api3('Tag', 'create', array('name' => 'Orange', 'description' => 'Orange you glad this isn\'t a pun?', 'color' => '#ff9d2a', 'parent_id' => $fruit['id']));

civicrm_api3('Tag', 'create', array( 'name' => 'Edge Case', 'description' => 'Edge Case', 'color' => '#000000', 'used_for' => array('civicrm_case')));
civicrm_api3('Tag', 'create', array( 'name' => 'Strenuous', 'description' => 'Strenuous activity',  'color' => '#00ff00','used_for' => array('civicrm_activity')));
civicrm_api3('Tag', 'create', array( 'name' => 'Leisurely', 'description' => 'Leisurely activity',  'color' => '#006f00','used_for' => array('civicrm_activity')));
