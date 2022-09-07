<?php

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
   * Pid of the current process.
   *
   * @var int
   */
  private $pid;

  private $minDelay = 1;
  private $maxDelay = 4;

  /**
   * @param string $file the file for which we want a lock
   * @param string|null $lockFile the file which represents the lock; if null, autogenerate
   * @param int|null $pid the process which holds the lock; if null, the current process
   */
  public function __construct($file, $lockFile = NULL, $pid = NULL) {
    $this->file = $file;
    $this->lockFile = $lockFile ? $lockFile : "{$file}.lock";
    $this->pid = $pid ? $pid : posix_getpid();
  }

  /**
   * @param int $wait max time to wait to acquire lock (seconds)
   * @return bool TRUE if acquired; else false
   */
  public function acquire($wait) {
    // total total spent waiting so far (seconds)
    $totalDelay = 0;
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

  public function release() {
    if (file_exists($this->lockFile)) {
      $lockPid = (int) trim(file_get_contents($this->lockFile));
      if ($lockPid == $this->pid) {
        unlink($this->lockFile);
      }
    }
  }

  public function steal() {
    file_put_contents($this->lockFile, $this->pid);
  }

}
