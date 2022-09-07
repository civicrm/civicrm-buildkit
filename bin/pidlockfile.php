#!/usr/bin/env php
<?php
ini_set('display_errors', 1);

// Claim a lock on behalf of a given PID.  The lock is considered released
// when either (a) the lock file is deleted or (b) the PID becomes invalid.
//
// usage: pidlockfile.php <lock-file> <pid> <wait>
//
// example:
//  if php lockfile.php /path/to/my.lock $$ 60 ; then
//    echo "OK to proceed"
//    rm -f /path/to/my.lock
//  else
//    echo "Failed to acquire /path/to/my.lock"
//  fi

if (!function_exists('posix_getpid') || !function_exists('posix_getpgid')) {
  fwrite(STDERR, "WARNING: pidlockfile.php: POSIX API is unavailable. Cannot lock resources. Concurrent operations may be problematic.\n");
  exit(0);
}
require_once dirname(__DIR__) . '/src/PidLock.php';
if (count($argv) != 4) {
  echo "Usage: pidlockfile.php <lock-file> <pid> <wait>\n";
  exit(2);
}
list ($program, $lock_file,  $parent_pid, $wait) = $argv;
$lock = new PidLock(NULL, $lock_file, $parent_pid);
exit($lock->acquire($wait) ? 0 : 1);
