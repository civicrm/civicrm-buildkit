#!/usr/bin/env php
<?php
## usage: module-enable.php <module_a> <module_b> ...
ini_set('display_errors', 1);

$_SERVER['HTTP_HOST']       = 'default';
$_SERVER['PHP_SELF']        = '/index.php';
$_SERVER['REMOTE_ADDR']     = '127.0.0.1';
$_SERVER['SERVER_SOFTWARE'] = NULL;
$_SERVER['REQUEST_METHOD']  = 'GET';
$_SERVER['QUERY_STRING']    = '';
$_SERVER['PHP_SELF']        = $_SERVER['REQUEST_URI'] = '/';
$_SERVER['HTTP_USER_AGENT'] = 'console';

define('BACKDROP_ROOT', '.');
require_once 'core/includes/bootstrap.inc';
backdrop_bootstrap(BACKDROP_BOOTSTRAP_FULL);

$modules = $argv;
$program = array_shift($modules);

if (empty($modules)) {
  echo "usage: $program <module_a> <module_b> ...\n";
  exit(0);
}
else {
  printf("[[ Enable %s ]]\n", implode(', ', $modules));
  module_enable($modules);
  backdrop_flush_all_caches();

  $messages = backdrop_get_messages();
  if (!empty($messages)) {
    print_r($messages);
  }

}