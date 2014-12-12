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

if (count($argv) != 4) {
  echo "Usage: pidlockfile.php <lock-file> <pid> <wait>\n";
  exit(2);
}
list ($program, $lock_file,  $parent_pid, $wait) = $argv;
$lock = new PidLock(NULL, $lock_file, $parent_pid);
exit($lock->acquire($wait) ? 0 : 1);

/**
 * Acquire a PID-based lock on a file.
 *
 * The lock is owned by a particular PID and remains
 * valid until the PID disappears (or until the lock
 * is released or stolen).
 */
class PidLock {
  /**
   * @var string
   */
  private $file;

  /**
   * @var string
   */
  private $lockFile;

  /**
   * @var int pid of the current process
   */
  private $pid;

  private $minDelay = 1;
  private $maxDelay = 4;

  /**
   * @param string $file the file for which we want a lock
   * @param string|null $lockFile the file which represents the lock; if null, autogenerate
   * @param int|null $pid the process which holds the lock; if null, the current process
   */
  function __construct($file, $lockFile = NULL, $pid = NULL) {
    $this->file = $file;
    $this->lockFile = $lockFile ? $lockFile : "{$file}.lock";
    $this->pid = $pid ? $pid : posix_getpid();
  }

  /**
   * @param int $wait max time to wait to acquire lock (seconds)
   * @return bool TRUE if acquired; else false
   */
  function acquire($wait) {
    $totalDelay = 0; // total total spent waiting so far (seconds)
    $nextDelay = 0;
    while ($totalDelay < $wait) {
      if ($nextDelay) {
        sleep($nextDelay);
        $totalDelay += $nextDelay;
      }

      if (!file_exists($this->lockFile)) {
        file_put_contents($this->lockFile, $this->pid);
        return TRUE;
      }

      $lockPid = (int) trim(file_get_contents($this->lockFile));
      if ($lockPid == $this->pid) {
        return TRUE;
      }

      if (!posix_getpgid($lockPid)) {
        file_put_contents($this->lockFile, $this->pid);
        return TRUE;
      }

      $nextDelay = rand($this->minDelay, min($this->maxDelay, $wait - $totalDelay));
    }
    return FALSE;
  }

  function release() {
    if (file_exists($this->lockFile)) {
      $lockPid = (int) trim(file_get_contents($this->lockFile));
      if ($lockPid == $this->pid) {
        unlink($this->lockFile);
      }
    }
  }

  function steal() {
    file_put_contents($this->lockFile, $this->pid);
  }
}