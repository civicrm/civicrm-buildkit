<?php
namespace Civici\Util;

class JUnitLoaderTeest extends \Civici\CiviciTestCase {

  public function testCount() {
    $junit = new JUnitLoader();
    $junit->addFolder(dirname(__DIR__) . '/junit-examples');
    $vars = $junit->getVars();
    $this->assertEquals('failure', $vars['@JUNIT_STATE@']);
    $this->assertEquals(2, $vars['@JUNIT_FAILURES@']);
    $this->assertEquals(4, $vars['@JUNIT_TESTS@']);
    $this->assertEquals(0, $vars['@JUNIT_ERRORS@']);
    $this->assertEquals('1m5.07s', $vars['@JUNIT_TIME@']);
    $this->assertEquals('Executed 4 tests in 1m5.07s - 2 failure(s), 0 error(s)', $vars['@JUNIT_SUMMARY@']);
  }

  public function testLoadTwice() {
    $junit = new JUnitLoader();
    $junit->addFile(dirname(__DIR__) . '/junit-examples/headless.xml');
    $junit->addFile(dirname(__DIR__) . '/junit-examples/headless.xml');
    $vars = $junit->getVars();
    $this->assertEquals('failure', $vars['@JUNIT_STATE@']);
    $this->assertEquals(2, $vars['@JUNIT_FAILURES@']);
    $this->assertEquals(4, $vars['@JUNIT_TESTS@']);
    $this->assertEquals(0, $vars['@JUNIT_ERRORS@']);
    $this->assertEquals('0.04s', $vars['@JUNIT_TIME@']);
    $this->assertEquals('Executed 4 tests in 0.04s - 2 failure(s), 0 error(s)', $vars['@JUNIT_SUMMARY@']);
  }

}
