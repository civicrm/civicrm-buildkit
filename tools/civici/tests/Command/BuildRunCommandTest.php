<?php
namespace ExtTestRun\Command;

class BuildRunCommandTest extends \ExtTestRun\ExtTestRunTestCase {
  public function setup() {
    parent::setup();
  }

  /**
   * If the fixturePath has no git repos, then the export lists no details.
   */
  public function testLs_noOutput() {
    $commandTester = $this->createCommandTester(array(
      'command' => 'build-run',
      'ext-repo' => array($this->fixturePath),
    ));
    $this->assertRegExp('/Hello world/', $commandTester->getDisplay(FALSE));
  }

}
