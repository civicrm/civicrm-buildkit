<?php
namespace Civici\Util;

use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;

class JUnitLoader {

  private $tests = 0, $failures = 0, $errors = 0, $time = 0.0, $failedXml = FALSE;

  private $exitCode = NULL;

  /**
   * @param $file
   * @return $this
   */
  public function addFile($file) {
    $xml = simplexml_load_file($file);
    foreach ($xml->testsuite as $testsuite) {
      $this->tests += (int) $testsuite['tests'];
      $this->failures += (int) $testsuite['failures'];
      $this->errors += (int) $testsuite['errors'];
      $this->time += (double) $testsuite['time'];
    }
    return $this;
  }

  /**
   * @param $path
   * @return $this
   */
  public function addFolder($path) {
    $fs = new Filesystem();
    $files = (array) glob($fs->withTrailingSlash($path) . '*.xml');
    if (empty($files)) {
      $this->failedXml = TRUE;
      return $this;
    }
    foreach ($files as $file) {
      $this->addFile($file);
    }
    return $this;
  }

  public function getVars() {
    $vars = [
      '@JUNIT_TESTS@' => $this->tests,
      '@JUNIT_TIME@' => $this->formatTime($this->time),
      '@JUNIT_FAILURES@' => $this->failures,
      '@JUNIT_ERRORS@' => $this->errors,
      '@JUNIT_EXIT@' => empty($this->exitCode) ? 0 : $this->exitCode,
    ];

    if ($this->failedXml) {
      $vars['@JUNIT_STATE@'] = 'failure';
      $vars['@JUNIT_SUMMARY@'] = strtr('Failed to load JUnit XML data. Perhaps the test process crashed?', $vars);
    }
    else {
      $vars['@JUNIT_STATE@'] = ($vars['@JUNIT_ERRORS@'] + $vars['@JUNIT_FAILURES@'] > 0 || $vars['@JUNIT_EXIT@'] != 0)
        ? 'failure'
        : 'success';

      $vars['@JUNIT_SUMMARY@'] = strtr('Executed @JUNIT_TESTS@ tests in @JUNIT_TIME@ - @JUNIT_FAILURES@ failure(s), @JUNIT_ERRORS@ error(s)', $vars);

      if ($vars['@JUNIT_EXIT@'] != 0) {
        $vars['@JUNIT_SUMMARY@'] = 'Exited with error. ' . $vars['@JUNIT_SUMMARY@'];
      }
    }

    return $vars;
  }

  protected function formatTime($total) {
    if ($total > 60) {
      $min = floor($total / 60);
      $sec = $total - ($min * 60); // Preserve decimal
      return sprintf("%dm%.2fs", $min, $sec);
    }
    else {
      return sprintf("%.2fs", $total);
    }
  }

  /**
   * @return mixed
   *   The exit-code from running the phpunit/junit command.
   *   May be an empty string or null if unknown.
   */
  public function getExitCode() {
    return $this->exitCode;
  }

  /**
   * @param mixed $exitCode
   *   The exit-code from running the phpunit/junit command.
   *   May be an empty string or null if unknown.
   * @return $this
   */
  public function setExitCode($exitCode) {
    $this->exitCode = $exitCode;
    return $this;
  }

}
