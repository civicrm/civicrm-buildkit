<?php

use \Civi\Civibuild\ProcessUtil;

class CivibuildUrlTest extends \Civi\Civibuild\CivibuildTestCase {

  /**
   * @var string
   * Create a build with the given type (BUILDKIT/app/config/BUILDTYPE).
   */
  protected $buildType = 'empty';

  /**
   * @var string
   * Create a build with the given name (e.g. BUILDKIT/build/BUILDNAME).
   */
  protected $buildName = 'testdgtxlifi';

  /**
   * @var string
   * Create a build with the given alias (via civibuild.aliases.sh).
   */
  protected $alias = 'testalias-anujrdw';

  protected function setUp() {
    parent::setUp();
    $fs = new \Symfony\Component\Filesystem\Filesystem();
    $fs->remove($this->getAbsPath($this->alias));
    $fs->remove($this->getAbsPath($this->alias . '.sh'));
    $fs->remove($this->getAbsPath($this->buildName));
    $fs->remove($this->getAbsPath($this->buildName . '.sh'));
    ProcessUtil::runOk($this->cmd('amp cleanup'));
  }

  public function getCases() {
    $cases = array();

    $cases[] = array(
      "civibuild create {$this->buildName} --type {$this->buildType} --url-template '%AUTO%'",
      'http://localhost:7979',
    );
    $cases[] = array(
      "civibuild create {$this->buildName} --type {$this->buildType} --url 'http://foo.example.com'",
      "http://foo.example.com",
    );
    $cases[] = array(
      "civibuild create {$this->buildName} --type {$this->buildType} --url-template 'http://www.%SITE_NAME%.ex'",
      "http://www.{$this->buildName}.ex",
    );
    $cases[] = array(
      "civibuild create {$this->alias} --url-template '%AUTO%'",
      "http://{$this->alias}.test",
    );
    $cases[] = array(
      "civibuild create {$this->alias} --url-template 'http://www.%SITE_NAME%.ex'",
      "http://www.{$this->alias}.ex",
    );
    $cases[] = array(
      "civibuild create {$this->alias} --url 'http://foo.example.com'",
      "http://foo.example.com",
    );

    return $cases;
  }

  /**
   * @param string $command
   * @param string $expectedUrl
   * @dataProvider getCases
   */
  public function testBuildUrl($command, $expectedUrl) {
    $result = ProcessUtil::runOk($this->cmd($command));
    $this->assertRegExp(";Execute [^\n]*/download.sh;", $result->getOutput());
    $this->assertRegExp(";Execute [^\n]*/install.sh;", $result->getOutput());
    $this->assertContains("- CMS_URL: $expectedUrl\n", $result->getOutput());
  }

}
