<?php

use \Civi\Civibuild\ProcessUtil;

/**
 * Class CivibuildCreateTest
 *
 * This test checks that the general mechanics of creating/listing/destroying sites
 * works. However, it does using a dummy (empty) site, and it does not make use of
 * many options.
 */
class CivibuildGeneralTest extends \Civi\Civibuild\CivibuildTestCase {

  protected $buildType = 'empty';
  protected $buildName = 'testdgtxlifi';

  protected function setUp() {
    parent::setUp();
    $fs = new \Symfony\Component\Filesystem\Filesystem();
    $fs->remove($this->getAbsPath($this->buildName));
    $fs->remove($this->getAbsPath($this->buildName . '.sh'));
    ProcessUtil::runOk($this->cmd('amp cleanup'));
  }

  public function testCreate_Show_Destroy() {
    $result = ProcessUtil::runOk($this->cmd(
      "civibuild create {$this->buildName} --type $this->buildType"
    ));
    $this->assertRegExp(";Execute [^\n]*/app/config/{$this->buildType}/download.sh;", $result->getOutput());
    $this->assertRegExp(";Execute [^\n]*/app/config/{$this->buildType}/install.sh;", $result->getOutput());
    $this->assertRegExp("; - CMS_ROOT: [^\n]*/{$this->buildName};", $result->getOutput());
    $this->assertRegExp('; - CIVI_DB_DSN: mysql://.*:.*@.*/.*;', $result->getOutput());
    $this->assertTrue(file_exists($this->getAbsPath($this->buildName)));
    $this->assertTrue(file_exists($this->getAbsPath($this->buildName . '.sh')));

    $result = ProcessUtil::runOk($this->cmd(
      "civibuild show {$this->buildName}"
    ));
    $this->assertNotRegExp(";Execute [^\n]*/app/config/{$this->buildType}/download.sh;", $result->getOutput());
    $this->assertNotRegExp(";Execute [^\n]*/app/config/{$this->buildType}/install.sh;", $result->getOutput());
    $this->assertRegExp("; - CMS_ROOT: [^\n]*/{$this->buildName};", $result->getOutput());
    $this->assertRegExp('; - CIVI_DB_DSN: mysql://.*:.*@.*/.*;', $result->getOutput());
    $this->assertTrue(file_exists($this->getAbsPath($this->buildName)));
    $this->assertTrue(file_exists($this->getAbsPath($this->buildName . '.sh')));

    $result = ProcessUtil::runOk($this->cmd(
      "echo y | civibuild destroy {$this->buildName}"
    ));
    $this->assertFalse(file_exists($this->getAbsPath($this->buildName)));
    $this->assertFalse(file_exists($this->getAbsPath($this->buildName . '.sh')));
  }

  public function testDownload_Install_Reinstall_Destroy() {
    $result = ProcessUtil::runOk($this->cmd(
      "civibuild download {$this->buildName} --type $this->buildType"
    ));
    $this->assertRegExp(";Execute [^\n]*/app/config/{$this->buildType}/download.sh;", $result->getOutput());
    $this->assertNotRegExp(";Execute [^\n]*/app/config/{$this->buildType}/install.sh;", $result->getOutput());
    $this->assertNotRegExp("; - CMS_ROOT: [^\n]*/{$this->buildName};", $result->getOutput());
    $this->assertNotRegExp('; - CIVI_DB_DSN: mysql://.*:.*@.*/.*;', $result->getOutput());
    $this->assertTrue(file_exists($this->getAbsPath($this->buildName)));
    $this->assertTrue(file_exists($this->getAbsPath($this->buildName . '.sh')));

    $result = ProcessUtil::runOk($this->cmd(
      "civibuild install {$this->buildName}"
    ));
    $this->assertNotRegExp(";Execute [^\n]*/app/config/{$this->buildType}/download.sh;", $result->getOutput());
    $this->assertRegExp(";Execute [^\n]*/app/config/{$this->buildType}/install.sh;", $result->getOutput());
    $this->assertRegExp("; - CMS_ROOT: [^\n]*/{$this->buildName};", $result->getOutput());
    $this->assertRegExp('; - CIVI_DB_DSN: mysql://.*:.*@.*/.*;', $result->getOutput());
    $this->assertTrue(file_exists($this->getAbsPath($this->buildName)));
    $this->assertTrue(file_exists($this->getAbsPath($this->buildName . '.sh')));

    $result = ProcessUtil::runOk($this->cmd(
      "civibuild reinstall {$this->buildName}"
    ));
    $this->assertNotRegExp(";Execute [^\n]*/app/config/{$this->buildType}/download.sh;", $result->getOutput());
    $this->assertRegExp(";Execute [^\n]*/app/config/{$this->buildType}/install.sh;", $result->getOutput());
    $this->assertRegExp("; - CMS_ROOT: [^\n]*/{$this->buildName};", $result->getOutput());
    $this->assertRegExp('; - CIVI_DB_DSN: mysql://.*:.*@.*/.*;', $result->getOutput());
    $this->assertTrue(file_exists($this->getAbsPath($this->buildName)));
    $this->assertTrue(file_exists($this->getAbsPath($this->buildName . '.sh')));

    $result = ProcessUtil::runOk($this->cmd(
      "echo y | civibuild destroy {$this->buildName}"
    ));
    $this->assertFalse(file_exists($this->getAbsPath($this->buildName)));
    $this->assertFalse(file_exists($this->getAbsPath($this->buildName . '.sh')));
  }

  public function testList_Create_List_Destroy_List() {
    $result = ProcessUtil::runOk($this->cmd("civibuild list"));
    $this->assertNotContains($this->buildName, $result->getOutput());

    $result = ProcessUtil::runOk($this->cmd(
      "civibuild create {$this->buildName} --type $this->buildType"
    ));
    $this->assertRegExp("; - CMS_ROOT: [^\n]*/{$this->buildName};", $result->getOutput());

    $result = ProcessUtil::runOk($this->cmd("civibuild list"));
    $this->assertContains($this->buildName, $result->getOutput());

    $result = ProcessUtil::runOk($this->cmd(
      "echo y | civibuild destroy {$this->buildName}"
    ));
    $this->assertFalse(file_exists($this->getAbsPath($this->buildName)));
    $this->assertFalse(file_exists($this->getAbsPath($this->buildName . '.sh')));

    $result = ProcessUtil::runOk($this->cmd("civibuild list"));
    $this->assertNotContains($this->buildName, $result->getOutput());
  }

  public function getCommandsWhichSupportDefaultBuild() {
    return array(
      array('reinstall'),
      array('snapshot'),
      array('restore'),
      array('show'),
    );
  }

  /**
   * @param $command
   * @dataProvider getCommandsWhichSupportDefaultBuild
   */
  public function testUseDefaultBuildName($command) {
    $result = ProcessUtil::runOk($this->cmd(
      "civibuild create {$this->buildName} --type $this->buildType"
    ));
    $this->assertRegExp("; - CMS_ROOT: [^\n]*/{$this->buildName};", $result->getOutput());
    $this->assertRegExp('; - CIVI_DB_DSN: mysql://.*:.*@.*/.*;', $result->getOutput());
    $this->assertTrue(file_exists($this->getAbsPath($this->buildName)));
    $this->assertTrue(file_exists($this->getAbsPath($this->buildName . '.sh')));

    $buildDir = $this->getAbsPath($this->buildName);
    mkdir("$buildDir/subdir");

    // Run the command three different ways, and see if the results are the same.

    $resultWithArg = ProcessUtil::runOk($this->cmd("civibuild $command {$this->buildName}"));
    $this->assertNotEmpty($resultWithArg->getOutput());

    $resultInSubdir = ProcessUtil::runOk(
      $this->cmd("civibuild $command")->setWorkingDirectory("$buildDir/subdir")
    );

    $this->assertContains("[[Detected SITE_NAME: {$this->buildName}]]\n", $resultInSubdir->getOutput());
    $this->assertEquals(
      $resultWithArg->getOutput(),
      str_replace("[[Detected SITE_NAME: {$this->buildName}]]\n", "", $resultInSubdir->getOutput())
    );

    // FIXME: Bug!
    //    $resultInDir = ProcessUtil::runOk(
    //      $this->cmd("civibuild $command")->setWorkingDirectory($buildDir)
    //    );
    //    $this->assertContains("[[Detected SITE_NAME: {$this->buildName}]]\n", $resultInSubdir->getOutput());
    //    $this->assertEquals(
    //      $resultWithArg->getOutput(),
    //      str_replace("[[Detected SITE_NAME: {$this->buildName}]]\n", "", $resultInDir->getOutput())
    //    );
  }

}