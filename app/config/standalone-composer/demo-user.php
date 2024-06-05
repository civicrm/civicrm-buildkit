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

  $contactID = \Civi\Api4\Contact::create(FALSE)
    ->setValues([
      'contact_type' => 'Individual',
      'first_name' => 'Demo',
      'last_name' => 'User',
    ])
    ->execute()->first()['id'];
  $adminEmail = getenv('DEMO_EMAIL');
  $params = [
    'cms_name'   => getenv('DEMO_USER'),
    'cms_pass'   => getenv('DEMO_PASS'),
    'notify'     => FALSE,
    $adminEmail  => $adminEmail,
    'contact_id' => $contactID,
  ];
  $userID = \CRM_Core_BAO_CMSUser::create($params, $adminEmail);

  // Add the staff role to the demo user.
  \Civi\Api4\User::update(FALSE)
    ->addWhere('id', '=', $userID)
    ->addValue('roles:name', ['staff'])
    ->execute();

});
