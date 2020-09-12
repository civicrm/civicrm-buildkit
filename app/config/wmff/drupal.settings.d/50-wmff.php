<?php

global $databases;

$databases['donations']['default'] = $databases['default']['default'];
$databases['fredge']['default'] = $databases['default']['default'];
$databases['fredge']['default']['database'] = 'fredge';
$databases['default']['default']['prefix'] = [
  'default' => '',
  'payments_initial' => '`fredge`.',
  'payments_fraud' => '`fredge`.',
  'payments_fraud_breakdown' => '`fredge`.',
];

define('WMF_SOURCE_REVISION', 'integration');
