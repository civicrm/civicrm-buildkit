<?php
namespace Civici\Command;

use Symfony\Component\Console\Output\OutputInterface;

class ExtShaCreateCommandTest extends \Civici\CiviciTestCase {
  public function setup() {
    parent::setup();
  }

  /**
   * If the fixturePath has no git repos, then the export lists no details.
   */
  public function testApi4() {
    $commandTester = $this->createCommandTester(array(
      'command' => 'extsha:create',
      '--dry-run' => TRUE,
      '--build' => 'foobar',
      '--build-root' => '/srv/buildkit/build',
      'git-url' => 'https://github.com/civicrm/org.civicrm.api4',
      '--rev' => 'abcd1234abcd1234',
    ), ['verbosity' => OutputInterface::VERBOSITY_VERBOSE]);

    $linePatterns = [
      '%Download main codebase \(build=foobar, type=drupal-clean, civi-ver=master\)%',
      '%\$ cd \'.*\'%',
      '%\$ civibuild download \'foobar\' --type \'drupal-clean\' --civi-ver \'master\'%',

      '%Download extension \(https://github.com/civicrm/org.civicrm.api4 @ abcd1234abcd1234\)%',
      '%\$ cd \'/srv/buildkit/build/foobar\'%',
      '%\$ git clone \'https://github.com/civicrm/org.civicrm.api4\' \'sites/default/files/civicrm/ext/target\' --no-checkout --depth 1 && cd \'sites/default/files/civicrm/ext/target\' && git fetch origin \'abcd1234abcd1234\':\'target\' && git checkout \'target\'%',

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
