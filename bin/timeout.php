#!/usr/bin/env php
<?php
ini_set('display_errors', 1);
define('TIMEOUT_INTERVAL', 100000); // polling interval (microseconds) [==0.1s]
define('TIMEOUT_FINAL', 8); // time to wait for SIGTERM to succeed - before sending SIGKILL (seconds)

// Note: This is like GNU's timeout, but it runs with GNU- or BSD-userland
// Note: Tried using Symfony\Process but couldn't find a proper way to pass-thru stdin/stdout/stderr

/**
 * @param array<string> $origArgs
 * @return int exit code
 */
function timeout_main($origArgs) {
  $args = $origArgs;
  array_shift($args); // program name
  $timeout = array_shift($args);
  $cmd = (implode(' ', array_map('escapeshellarg', $args)));

  if (!is_numeric($timeout)) {
    fwrite(STDERR, "usage: timeout.php <seconds> <command>\n");
    return 1;
  }

  return timeout_passthru($cmd, $timeout);
}

/**
 * Execute an external command while applying a timeout
 *
 * @param string $cmd
 * @param int $timeout seconds to execute
 * @return int exit code
 */
function timeout_passthru($cmd, $timeout) {
  $process = proc_open($cmd, array(
    0 => STDIN,
    1 => STDOUT,
    2 => STDERR
  ), $pipes);

  $status = timeout_wait($process, $timeout);

  if (!$status['running']) {
    // We can end this the easy way
    return $status['exitcode'];
  }
  else {
    // We need to end this the hard way
    proc_terminate($process);
    $status = timeout_wait($process, TIMEOUT_FINAL);
    if ($status['running'] && defined('SIGKILL')) {
      proc_terminate($process, SIGKILL);
    }
    return 255;
  }
}

/**
 * Wait until the timeout expires or the process ends
 *
 * @param resource $process
 * @param int $timeout time to wait for $process to complete [seconds]
 * @param int $interval polling-interval (for checking $process status) [microseconds]
 * @return array the final status (per proc_get_status)
 */
function timeout_wait($process, $timeout, $interval = TIMEOUT_INTERVAL) {
  $endTime = microtime(TRUE) + $timeout;
  do {
    usleep($interval);
    $status = proc_get_status($process);
    $now = microtime(TRUE);
  } while ($status['running'] && $now <= $endTime);
  return $status;
}

exit(timeout_main($argv));