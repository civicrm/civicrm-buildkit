<?php

use \Civi\Civibuild\ProcessUtil;

/**
 * Class CivibuildCreateTest
 *
 * Execute "civibuild create" and ensure it prodcues a website.
 *
 * @todo Check if an instance named "civibuild-test" already exist before creating it
 * @todo Destroy created test intance after run "civibuild create ..." test
 */
class CivibuildCreateTest extends \Civi\Civibuild\CivibuildTestCase {

  /**
   * Create a test instance name Civibuild-test
   * (assumes no one will have created such an instance)
   */
  public function testWpDemo() {
    ProcessUtil::runOk($this->cmd(
      'civibuild create civibuild-test --force --type wp-demo --civi-ver master' .
      ' --url http://civibuild-test.localhost'
    ));

    $this->assertTrue(is_dir($this->getAbsPath('civibuild-test', 'wp-content/plugins/civicrm/civicrm/packages')));
    $this->assertFalse(file_exists($this->getAbsPath('civibuild-test', 'wp-content/plugins/civicrm/civicrm/packages/DUMMY-PATCH-DATA.txt')));
  }

  public function testWpDemoWithPatch() {
    $patchFile = __DIR__ . '/CivibuildCreateTest.dummy.patch';

    ProcessUtil::runOk($this->cmd(
      'civibuild create civibuild-test --force --type wp-demo --civi-ver master' .
      ' --url http://civibuild-test.localhost --patch ' . escapeshellarg(";civicrm-packages;$patchFile")
    ));

    $this->assertTrue(is_dir($this->getAbsPath('civibuild-test', 'wp-content/plugins/civicrm/civicrm/packages')));
    $this->assertTrue(file_exists($this->getAbsPath('civibuild-test', 'wp-content/plugins/civicrm/civicrm/packages/DUMMY-PATCH-DATA.txt')));
  }

}
