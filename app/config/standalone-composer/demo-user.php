<?php

// Add a demo user.

if (PHP_SAPI !== 'cli') {
  die("phpunit can only be run from command line.");
}

foreach (['DEMO_EMAIL', 'DEMO_USER', 'DEMO_PASS'] as $var) {
  if (empty(getenv($var))) {
    throw new \Exception("Missing: $var");
  }
}

// Since users+contacts are stored in same DB, we can do transaction.
CRM_Core_Transaction::create()->run(function () {

  $demoEmail = getenv('DEMO_EMAIL');
  $demoUser = getenv('DEMO_USER');
  $demoPass = getenv('DEMO_PASS');

  $contactID = \Civi\Api4\Contact::create(FALSE)
    ->addValue('contact_type', 'Individual')
    ->addValue('first_name', 'Demo')
    ->addValue('last_name', 'User')
    ->execute()->single()['id'];

  \Civi\Api4\Email::create(FALSE)
    ->addValue('email', $demoEmail)
    ->addValue('contact_id', $contactID)
    ->execute();

  // Create demo user with the "Administer" role
  \Civi\Api4\User::create(FALSE)
    ->addValue('username' , $demoUser)
    ->addValue('password' , $demoPass)
    ->addValue('contact_id' , $contactID)
    ->addValue('roles:name', ['staff'])
    ->execute();
});
