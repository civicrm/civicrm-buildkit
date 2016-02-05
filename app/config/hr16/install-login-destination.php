<?php

/**
 * @file
 *
 * Register login-destination rules
 */

$rules = array();
$rules[] = array(
  'triggers' => serialize(array('login' => 'login')),
  'roles' => serialize(array(55120974 => 55120974)),
  'pages_type' => 0,
  'pages' => '',
  'destination_type' => 0,
  'destination' => 'civicrm/tasksassignments/dashboard#/tasks',
  'weight' => 0,
);
$rules[] = array(
  'triggers' => serialize(array('logout' => 'logout')),
  'roles' => serialize(array()),
  'pages_type' => 0,
  'pages' => '',
  'destination_type' => 0,
  'destination' => '<front>',
  'weight' => 0,
);
$rules[] = array(
  'triggers' => serialize(array('login' => 'login')),
  'roles' => serialize(array(17087012 => 17087012, 57573969 => 57573969)),
  'pages_type' => 0,
  'pages' => '',
  'destination_type' => 0,
  'destination' => 'dashboard',
  'weight' => 0,
);


foreach ($rules as $rule) {
  if (FALSE === drupal_write_record('login_destination', $rule)) {
    throw new RuntimeException("Failed to create login_destination: " . var_export($rule, TRUE));
  }
}
