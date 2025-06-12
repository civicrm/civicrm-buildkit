#!/usr/bin/env pogo
<?php
#!ttl 10 years
#!require symfony/finder: ~4.4

## Generate a list of "stale" builds - either:
## - The build is objectively old.
## - The build is redundant because there's a newer build of the same PR.

###############################################################################
## Bootstrap

ini_set('display_errors', 1);

###############################################################################
class MyFinder {

  /**
   * @var int seconds since epoch
   */
  public $expireAt;

  /**
   * @var int seconds since epoch
   */
  public $redundantAt;

  /**
   * @var string regex
   *
   * The regex should have one match group which indicates
   * the batch.
   */
  public $batchExpr;

  public $buildDir;

  /**
   * Determine the name of the batch which contains $name.
   *
   * @param string $name
   * @return string|NULL
   */
  public function pickBatch($name) {
    if (preg_match($this->batchExpr, $name, $matches)) {
      return $matches[1];
    }
    else {
      return NULL;
    }
  }

  /**
   * @return array
   *   Ex: Array("core-1234" => array("core-1234-abcd", "core-1234-ef12")).
   */
  public function createBatches() {
    $batches = array();
    $files = new \Symfony\Component\Finder\Finder();
    $files->in($this->buildDir)
      ->depth('== 0')
      ->directories();
    foreach ($files as $file) {
      /** @var \Symfony\Component\Finder\SplFileInfo $file */
      if ($batch = $this->pickBatch($file->getBasename())) {
        $batches[$batch][] = $file->getBasename();
      }
    }
    return $batches;
  }

  /**
   * @return \Symfony\Component\Finder\Finder
   */
  public function find() {
    $self = $this;

    $batches = $this->createBatches();
    $newest = array(); // Array(string $batchName => string $buildName).
    foreach ($batches as $batchName => $batchFiles) {
      $newest[$batchName] = array_shift($batchFiles);
      $newestCtime = filectime($this->buildDir . DIRECTORY_SEPARATOR . $newest[$batchName]);
      foreach ($batchFiles as $file) {
        $thisCtime = filectime($this->buildDir . DIRECTORY_SEPARATOR . $file);
        if ($thisCtime > $newestCtime) {
          $newest[$batchName] = $file;
          $newestCtime = $thisCtime;
        }
      }
    }

    $f = new \Symfony\Component\Finder\Finder();
    $f->in($this->buildDir)
      ->depth('== 0')
      ->directories()
      ->filter(function (\SplFileInfo $file) use ($self, $newest, $batches) {
        $batch = $self->pickBatch($file->getBasename());
        if (!$batch) {
          return FALSE;
        }

        if ($file->getCTime() < $self->expireAt) {
          return TRUE;
        }

        if ($file->getCTime() < $self->redundantAt
          && $file->getBasename() !== $newest[$batch]
        ) {
          return TRUE;
        }

        return FALSE;
      });
    return $f;
  }

  public function validate() {
    $errors = array();
    if (!file_exists($this->buildDir)) {
      $errors[] = "Not a directory";
    }
    if (!is_numeric($this->expireAt)) {
      $errors[] = "Invalid expireAfter";
    }
    if (!is_numeric($this->redundantAt)) {
      $errors[] = "Invalid redundantAfter";
    }
    if (empty($this->batchExpr)) {
      $errors[] = "Missing batchExpr";
    }
    return $errors;
  }

}

###############################################################################
## Main
$myFinder = new MyFinder();
$myFinder->buildDir = @$argv[1];
$myFinder->expireAt = isset($argv[2]) ? time() - $argv[2] * 60 * 60 : NULL;
$myFinder->redundantAt = isset($argv[2]) ? time() - $argv[3] * 60 * 60 : NULL;
$myFinder->batchExpr = '/^([a-z0-9]+-[0-9]+-)/';

$errors = $myFinder->validate();
if ($errors) {
  fwrite(STDERR, print_r($errors, 1));
  $usage = "usage: find-stale-builds <build_dir> <expire_after_hours> <redundant_after_hours>\n"
    . "about: Find builds in <build_dir> which are either:\n"
    . "  a. Expired -- More than X hours old\n"
    . "  b. Redundant --Superceded by a similarly-named item *AND* more than X hours old.\n";
  fwrite(STDERR, $usage);
  exit(1);
}

foreach ($myFinder->find() as $m) {
  echo "$m\n";
}
