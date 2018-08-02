<?php
namespace Civici\Command;

use Civici\Util\ProcessBatch;

class ExtPrCreateCommandTest extends \Civici\CiviciTestCase {
  public function setup() {
    parent::setup();
  }

  /**
   * If the fixturePath has no git repos, then the export lists no details.
   */
  public function testApi4() {
    $commandTester = $this->createCommandTester(array(
      'command' => 'extpr:create',
      '--dry-run' => TRUE,
      '--build' => 'foobar',
      '--build-root' => '/srv/buildkit/build',
      'pr-url' => 'https://github.com/civicrm/org.civicrm.api4/pull/123',
    ));

    $linePatterns = [
      '%Build and execute test for https://github.com/civicrm/org.civicrm.api4/pull/123%',
      '%Build empty site%',
      '%\$ cd \'.*\'%',
      '%\$ civibuild download \'foobar\' --type drupal-clean --civi-ver \'master\'%',
      '%Clone extension%',
      '%\$ cd \'/srv/buildkit/build/foobar\'%',
      '%\$ git clonepr \'https://github.com/civicrm/org.civicrm.api4/pull/123\' \'sites/default/civicrm/ext/target\' --depth 1%' ,
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
