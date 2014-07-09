#!/usr/bin/env php
<?php

// Claim a lock on behalf of a given PID.  The lock is considered released
// when either (a) the lock file is deleted or (b) the PID becomes invalid.
//
// usage: pidlockfile.php <lock-file> <pid>
//
// example: 
//  if php lockfile.php /path/to/my.lock $$ ; then
//    echo "OK to proceed"
//    rm -f /path/to/my.lock
//  else
//    echo "Failed to acquire /path/to/my.lock"
//  fi


list ($program, $lock_file,  $parent_pid) = $argv;
$min_delay = 1; // seconds, briefest delay between trials
$max_delay = 5; // seconds, longest delay between trials
$total_delay = 0; // seconds, accumulated delay across all trials
$total_delay_limit = 60; // seconds, limit on how much delay can accumlate

while ($total_delay < $total_delay_limit) {
  if (!file_exists($lock_file)) {
    file_put_contents($lock_file, $parent_pid);
    exit(0);
  } else {
    $lock_pid = (int) trim(file_get_contents($lock_file));
    if ($lock_pid == $parent_pid) {
      exit(0);
    }

    if (!posix_getpgid($lock_pid)) {
      file_put_contents($lock_file, $parent_pid);
      exit(0);
    }

    $delay = rand($min_delay, $max_delay);
    sleep($delay);
    $total_delay += $delay;
  }
}
exit(1);