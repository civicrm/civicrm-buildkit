<?php
namespace Civici\Command;

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
      '%Download main codebase \(build=foobar, type=drupal-clean, civi-ver=master\)%',
      '%\$ cd \'.*\'%',
      '%\$ civibuild download \'foobar\' --type \'drupal-clean\' --civi-ver \'master\'%',

      '%Download extension PR \(https://github.com/civicrm/org.civicrm.api4/pull/123\)%',
      '%\$ cd \'/srv/buildkit/build/foobar\'%',
      '%\$ git clonepr --merged \'https://github.com/civicrm/org.civicrm.api4/pull/123\' \'sites/default/files/civicrm/ext/target\' --depth 1%',

      '%Download extension dependencies%',
      '%\$ cd \'/srv/buildkit/build/foobar\'%',
      '%\$ civici ext:dl-dep --info=\'sites/default/files/civicrm/ext/target\'/info.xml --feed=\'https://civicrm.org/extdir/ver=5.40.0\|uf=Bare\|status=\|ready=/single\' --to=\'/srv/buildkit/build/foobar/sites/default/files/civicrm/ext\'$%',

      '%Install main database%',
      '%\$ cd \'/srv/buildkit/build/foobar\'%',
      '%civibuild install \'foobar\'%',

      // '%Install extension%',
      // '%\$ cd \'/srv/buildkit/build/foobar\'%',
      // '%cv api extension.install path=\'/srv/buildkit/build/foobar/sites/default/files/civicrm/ext/target\'%',

      // '%Update database snapshot%',
      // '%\$ cd \'/srv/buildkit/build/foobar\'%',
      // '%civibuild snapshot \'foobar\'%',

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
