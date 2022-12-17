<?php
namespace Civici\Command;

use Symfony\Component\Console\Output\OutputInterface;

class ExtTestCommandTest extends \Civici\CiviciTestCase {
  public function setup(): void {
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
      '--junit-dir' => '/tmp/myjunit',
    ), ['verbosity' => OutputInterface::VERBOSITY_VERBOSE]);

    $linePatterns = [
      '%Parse extension info \(.*/info.xml\)%',
      '%Found extension \(org.example.civixexample\)%',

      '%Restore database%',
      '%\$ cd \'.*/org.example.civixexample\'%',
      '%\$ civibuild restore && cv ext:enable \'org.example.civixexample\'%',
      '%^\w*$%',

      '%Run PHPUnit group \(e2e\)%',
      '%\$ cd \'.*/org.example.civixexample\'%',
      '%\$ phpunit8 .*  --group e2e --log-junit \'/tmp/myjunit/e2e.xml\'%',
      '%^\w*$%',

      '%Restore database%',
      '%\$ cd \'.*/org.example.civixexample\'%',
      '%\$ civibuild restore && cv ext:enable \'org.example.civixexample\'%',
      '%^\w*$%',

      '%Run PHPUnit group \(headless\)%',
      '%\$ cd \'.*/org.example.civixexample\'%',
      '%\$ phpunit8 .* --group headless --log-junit \'/tmp/myjunit/headless.xml\'%',
      '%^\w*$%',

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
