<?php
namespace Civici\Util;
use Civici\Util\Process as ProcessUtil;

class ProcessTest extends \Civici\CiviciTestCase {
  public function testRunOk_pass() {
    $process = ProcessUtil::runOk(new \Symfony\Component\Process\Process("echo times were good"));
    $this->assertEquals("times were good", trim($process->getOutput()));
  }

  public function testRunOk_fail() {
    try {
      ProcessUtil::runOk(new \Symfony\Component\Process\Process("echo tragedy befell the software > /dev/stderr; exit 1"));
      $this->fail("Failed to generate expected exception");
    }
    catch (\Civici\Exception\ProcessErrorException $e) {
      $this->assertEquals("tragedy befell the software", trim($e->getProcess()->getErrorOutput()));
    }
  }

}
