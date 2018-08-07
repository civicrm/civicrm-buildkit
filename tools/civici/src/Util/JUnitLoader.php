<?php
namespace Civici\Util;

use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;

class JUnitLoader {

  private $tests = 0, $failures = 0, $errors = 0, $time = 0.0;

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
    foreach ($files as $file) {
      $this->addFile($file);
    }
    return $this;
  }

  public function getVars() {
    $vars = [
      '@junitTests' => $this->tests,
      '@junitTime' => $this->formatTime($this->time),
      '@junitFailures' => $this->failures,
      '@junitErrors' => $this->errors,
    ];

    $vars['@junitState'] = ($vars['@junitErrors'] + $vars['@junitFailures'] > 0)
      ? 'success'
      : 'failure';

    $vars['@junitSummary'] = strtr('Executed @junitTests tests in @junitTime: @junitFailures failure(s), @junitErrors error(s)', $vars);
    return $vars;
  }

  protected function formatTime($total) {
    if ($total > 60) {
//      $sec = ($total % 60);
      $min = floor($total / 60);
      $sec = $total - ($min * 60); // Preserve decimal
      return sprintf("%dm %.2fs", $min, $sec);
    }
    else {
      return sprintf("%.2fs", $total);
    }
  }

}
