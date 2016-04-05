<?php
namespace Civi\Civibuild;

/**
 * Class CivibuildTestCase
 *
 * A base class for tests which work with civibuild.
 */
class CivibuildTestCase extends \PHPUnit_Framework_TestCase {

  /**
   * The time to allow commands to execute.
   *
   * 30min = 30*60*60 = 108000
   */
  const TIMEOUT = 108000;

  /**
   * Prepare a command to run in the repo's directory
   *
   * @param $command
   * @return \Symfony\Component\Process\Process
   */
  public function cmd($command) {
    $process = new \Symfony\Component\Process\Process($command);
    $process->setWorkingDirectory($this->getPrjDir());
    $process->setTimeout(self::TIMEOUT);
    return $process;
  }

  /**
   * Get the absolute path to a file in a build.
   *
   * @param string $buildName
   * @param string|null $relPath
   * @return string
   */
  public function getAbsPath($buildName, $relPath = NULL) {
    $absPath = $this->getPrjDir() . '/build/' . $buildName;
    if ($relPath) {
      $absPath .= '/' . $relPath;
    }
    return $absPath;
  }

  /**
   * Get the buildkit project dir (base dir).
   *
   * @return string
   */
  public function getPrjDir() {
    return dirname(dirname(dirname(__DIR__)));
  }

}
