<?php
namespace Civici\Command;

use Civici\Util\CacheDir;
use Symfony\Component\Console\Output\OutputInterface;

class ExtBuildCommandTest extends \Civici\CiviciTestCase {

  public function setup(): void {
    parent::setup();
    $this->fs->remove(CacheDir::get());
    CacheDir::writeFile('master-version.txt', '5.40.0');
  }

  public function tearDown(): void {
    $this->fs->remove(CacheDir::get());
    parent::tearDown();
  }

  /**
   * Simulate creation of an extension test-build using a Github PR URL.
   */
  public function testCreateByPr() {
    $commandTester = $this->createCommandTester(array(
      'command' => 'ext:build',
      '--dry-run' => TRUE,
      '--build' => 'foobar',
      '--build-root' => '/srv/buildkit/build',
      '--pr-url' => 'https://github.com/civicrm/org.civicrm.api4/pull/123',
    ), ['verbosity' => OutputInterface::VERBOSITY_VERBOSE]);

    $linePatterns = [
      '%Download main codebase \(build=foobar, type=drupal-clean, civi-ver=master\)%',
      '%\$ cd \'.*\'%',
      '%\$ civibuild download \'foobar\' --type \'drupal-clean\' --civi-ver \'master\'%',
      '%^\w*$%',

      '%Download extension PR \(https://github.com/civicrm/org.civicrm.api4/pull/123\)%',
      '%\$ cd \'/srv/buildkit/build/foobar\'%',
      '%\$ git clonepr --merged \'https://github.com/civicrm/org.civicrm.api4/pull/123\' \'web/sites/default/files/civicrm/ext/target\' --depth 1%',
      '%^\w*$%',

      '%Download extension dependencies%',
      '%\$ cd \'/srv/buildkit/build/foobar\'%',
      '%\$ civici ext:dl-dep --info=\'web/sites/default/files/civicrm/ext/target\'/info.xml --feed=\'https://civicrm.org/extdir/ver=5.40.0\|uf=Bare\|status=\|ready=/single\' --to=\'/srv/buildkit/build/foobar/web/sites/default/files/civicrm/ext\'$%',
      '%^\w*$%',

      '%Install main database%',
      '%\$ cd \'/srv/buildkit/build/foobar\'%',
      '%civibuild install \'foobar\'%',
      '%^\w*$%',

      // '%Install extension%',
      // '%\$ cd \'/srv/buildkit/build/foobar\'%',
      // '%cv api extension.install path=\'/srv/buildkit/build/foobar/web/sites/default/files/civicrm/ext/target\'%',
      // '%^\w*$%',

      // '%Update database snapshot%',
      // '%\$ cd \'/srv/buildkit/build/foobar\'%',
      // '%civibuild snapshot \'foobar\'%',
      // '%^\w*$%',

      '%Done%',
      '%%',
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

  /**
   * Simulate creation of an extension test-build using a Git URL and SHA.
   */
  public function testCreateBySha() {
    $commandTester = $this->createCommandTester(array(
      'command' => 'ext:build',
      '--dry-run' => TRUE,
      '--build' => 'foobar',
      '--build-root' => '/srv/buildkit/build',
      '--git-url' => 'https://github.com/civicrm/org.civicrm.api4',
      '--rev' => 'abcd1234abcd1234',
    ), ['verbosity' => OutputInterface::VERBOSITY_VERBOSE]);

    $linePatterns = [
      '%Download main codebase \(build=foobar, type=drupal-clean, civi-ver=master\)%',
      '%\$ cd \'.*\'%',
      '%\$ civibuild download \'foobar\' --type \'drupal-clean\' --civi-ver \'master\'%',
      '%^\w*$%',

      '%Download extension \(https://github.com/civicrm/org.civicrm.api4 @ abcd1234abcd1234\)%',
      '%\$ cd \'/srv/buildkit/build/foobar\'%',
      '%\$ git clone \'https://github.com/civicrm/org.civicrm.api4\' \'web/sites/default/files/civicrm/ext/target\' --no-checkout --depth 1 && cd \'web/sites/default/files/civicrm/ext/target\' && git fetch origin \'abcd1234abcd1234\':\'target\' && git checkout \'target\'%',
      '%^\w*$%',

      '%Download extension dependencies%',
      '%\$ cd \'/srv/buildkit/build/foobar\'%',
      '%\$ civici ext:dl-dep --info=\'web/sites/default/files/civicrm/ext/target\'/info.xml --feed=\'https://civicrm.org/extdir/ver=5.40.0\|uf=Bare\|status=\|ready=/single\' --to=\'/srv/buildkit/build/foobar/web/sites/default/files/civicrm/ext\'$%',
      '%^\w*$%',

      '%Install main database%',
      '%\$ cd \'/srv/buildkit/build/foobar\'%',
      '%civibuild install \'foobar\'%',
      '%^\w*$%',

      // '%Install extension%',
      // '%\$ cd \'/srv/buildkit/build/foobar\'%',
      // '%cv api extension.install path=\'/srv/buildkit/build/foobar/web/sites/default/files/civicrm/ext/target\'%',

      // '%Update database snapshot%',
      // '%\$ cd \'/srv/buildkit/build/foobar\'%',
      // '%civibuild snapshot \'foobar\'%',

      '%Done%',
      '%%',
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

  /**
   * Simulate creation of an extension test-build using a Git URL and SHA.
   */
  public function testCreateByBaseAndHead() {
    $commandTester = $this->createCommandTester(array(
      'command' => 'ext:build',
      '--dry-run' => TRUE,
      '--build' => 'foobar',
      '--build-root' => '/srv/buildkit/build',
      '--git-url' => 'https://github.com/civicrm/org.civicrm.api4',
      '--base' => 'abcd1234abcd1234',
      '--head' => 'fedc4321fedc4321',
    ), ['verbosity' => OutputInterface::VERBOSITY_VERBOSE]);

    $linePatterns = [
      '%Download main codebase \(build=foobar, type=drupal-clean, civi-ver=master\)%',
      '%\$ cd \'.*\'%',
      '%\$ civibuild download \'foobar\' --type \'drupal-clean\' --civi-ver \'master\'%',
      '%^\w*$%',

      '%Download extension \(https://github.com/civicrm/org.civicrm.api4 @ abcd1234abcd1234 . fedc4321fedc4321\)%',
      '%\$ cd \'/srv/buildkit/build/foobar\'%',
      '%\$ git clonebh \'https://github.com/civicrm/org.civicrm.api4\' \'web/sites/default/files/civicrm/ext/target\' \'abcd1234abcd1234\' \'fedc4321fedc4321\'%',
      '%^\w*$%',

      '%Download extension dependencies%',
      '%\$ cd \'/srv/buildkit/build/foobar\'%',
      '%\$ civici ext:dl-dep --info=\'web/sites/default/files/civicrm/ext/target\'/info.xml --feed=\'https://civicrm.org/extdir/ver=5.40.0\|uf=Bare\|status=\|ready=/single\' --to=\'/srv/buildkit/build/foobar/web/sites/default/files/civicrm/ext\'$%',
      '%^\w*$%',

      '%Install main database%',
      '%\$ cd \'/srv/buildkit/build/foobar\'%',
      '%civibuild install \'foobar\'%',
      '%^\w*$%',

      // '%Install extension%',
      // '%\$ cd \'/srv/buildkit/build/foobar\'%',
      // '%cv api extension.install path=\'/srv/buildkit/build/foobar/web/sites/default/files/civicrm/ext/target\'%',
      // '%^\w*$%',

      // '%Update database snapshot%',
      // '%\$ cd \'/srv/buildkit/build/foobar\'%',
      // '%civibuild snapshot \'foobar\'%',
      // '%^\w*$%',

      '%Done%',
      '%%',
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
