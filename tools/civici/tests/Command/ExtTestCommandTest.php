<?php
namespace Civici\Command;

use Symfony\Component\Console\Output\OutputInterface;

class ExtTestCommandTest extends \Civici\CiviciTestCase {
  public function setup() {
    parent::setup();
  }

  /**
   * If the fixturePath has no git repos, then the export lists no details.
   */
  public function testApi4() {
    $commandTester = $this->createCommandTester(array(
      'command' => 'ext:test',
      '--dry-run' => TRUE,
      '--info' => dirname(dirname(__DIR__)) . '/fixtures/org.example.civixexample/info.xml',
    ), ['verbosity' => OutputInterface::VERBOSITY_VERBOSE]);

    $linePatterns = [
      '%Parse extension info .*/info.xml%',
      '%Found extension org.example.civixexample%',

      '%Restore database%',
      '%\$ cd \'.*/org.example.civixexample\'%',
      '%\$ civibuild restore && cv ext:enable \'org.example.civixexample\'%',

      '%Run PHPUnit group \(e2e\)%',
      '%\$ cd \'.*/org.example.civixexample\'%',
      '%\$ phpunit4 --tap --group e2e%',

      '%Restore database%',
      '%\$ cd \'.*/org.example.civixexample\'%',
      '%\$ civibuild restore && cv ext:enable \'org.example.civixexample\'%',

      '%Run PHPUnit group \(headless\)%',
      '%\$ cd \'.*/org.example.civixexample\'%',
      '%\$ phpunit4 --tap --group headless%',

      '%Done%',
      '%%'
    ];

    $allOutput = $commandTester->getDisplay(FALSE);
    $lines = explode("\n", $allOutput);
    foreach ($lines as $n => $line) {
      if (!isset($linePatterns[$n])) {
        $this->fail("Failed to find pattern for line $n ($line)");
      }
      $this->assertRegExp($linePatterns[$n], $line, "Line $n ($line) does not match {$linePatterns[$n]} in output: $allOutput");
    }

  }

}
