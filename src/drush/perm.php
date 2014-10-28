<?php

## Read a list of roles and permissions from standard input;
## grant every role to every permission.

## Example:
## drush scr perm.php <<EOF
##   # Some stuff
##   role "first role"
##   role "second role"
##   add "first perm"
##   add "second perm"
##   remove "third perm"
## EOF

function _drush_role_perm_each($action, $roles, $perms) {
  foreach ($roles as $role) {
    foreach ($perms as $perm) {
      $result = drush_role_perm($action, $role, $perm);
      //$result doesn't differentiate error (failed) and already-done
      //if ($result !== FALSE) {
      //  fwrite(STDERR, "Failed to $action [$perm] for [$role]\n");
      //}      
    }
  }
}

$roles = array(); // array(string $role)
$lines = preg_split('/[;\r\n]+/', file_get_contents('php://stdin'));
foreach ($lines as $line) {
  $line = trim($line);
  if (empty($line) || preg_match('/^#/', $line)) {
    continue;
  }
  if (preg_match('/^flush roles$/', $line)) {
    $roles = array();
  }
  if (preg_match('/^role (.+)$/', $line, $matches)) {
    $roles[] = trim(trim($matches[1]), "'\"");
  } elseif(preg_match('/(add|remove) (.+)$/', $line, $matches)) {
    $perm = trim(trim($matches[2]), "'\"");
    _drush_role_perm_each($matches[1], $roles, array($perm));
  }
}

drush_drupal_cache_clear_all();
