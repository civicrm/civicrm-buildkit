<?php
namespace Civici\Util;

class JUnitLoaderTeest extends \Civici\CiviciTestCase {

  public function testCount() {
    $junit = new JUnitLoader();
    $junit->addFolder(dirname(__DIR__) . '/junit-examples');
    $vars = $junit->getVars();
    $this->assertEquals(2, $vars['@junitFailures']);
    $this->assertEquals(4, $vars['@junitTests']);
    $this->assertEquals(0, $vars['@junitErrors']);
    $this->assertEquals('1m 5.07s', $vars['@junitTime']);
    $this->assertEquals('Executed 4 tests in 1m 5.07s: 2 failure(s), 0 error(s)', $vars['@junitSummary']);
  }

  public function testLoadTwice() {
    $junit = new JUnitLoader();
    $junit->addFile(dirname(__DIR__) . '/junit-examples/headless.xml');
    $junit->addFile(dirname(__DIR__) . '/junit-examples/headless.xml');
    $vars = $junit->getVars();
    $this->assertEquals(2, $vars['@junitFailures']);
    $this->assertEquals(4, $vars['@junitTests']);
    $this->assertEquals(0, $vars['@junitErrors']);
    $this->assertEquals('0.04s', $vars['@junitTime']);
    $this->assertEquals('Executed 4 tests in 0.04s: 2 failure(s), 0 error(s)', $vars['@junitSummary']);
  }

}
