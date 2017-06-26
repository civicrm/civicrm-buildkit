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
