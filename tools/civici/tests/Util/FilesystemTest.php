<?php
namespace Civici\Util;

class FilesystemTest extends \Civici\CiviciTestCase {
  public function dataIsDescendent() {
    return array(
      array('/ex', '/ex', FALSE),
      array('/ex', '/ex/', FALSE),
      array('/ex/', '/ex', FALSE),
      array('/ex/', '/ex/', FALSE),
      array('/ex', '/ex/one', FALSE),
      array('/ex', '/ex/one/', FALSE),
      array('/ex/', '/ex/one', FALSE),
      array('/ex/', '/ex/one/', FALSE),
      array('/ex', '/ex1', FALSE),
      array('/ex', '/ex1/', FALSE),
      array('/ex/', '/ex1', FALSE),
      array('/ex/', '/ex1/', FALSE),
      array('/ex/one', '/ex', TRUE),
      array('/ex/one', '/ex/', TRUE),
      array('/ex/one/', '/ex', TRUE),
      array('/ex/one/', '/ex/', TRUE),
      array('/ex1', '/ex', FALSE),
      array('/ex1', '/ex/', FALSE),
      array('/ex1/', '/ex', FALSE),
      array('/ex1/', '/ex/', FALSE),

    );
  }

  /**
   * @param string $child
   * @param string $parent
   * @param bool $expected
   * @dataProvider dataIsDescendent
   */
  public function testIsDescendent($child, $parent, $expected) {
    $fs = new Filesystem();
    $this->assertEquals($expected, $fs->isDescendent($child, $parent));
  }

  public function dataFormatPrettyPath() {
    return array(
      array('/var/www', array('/var/www'), 'www'),
      array('/var/www/drupal', array('/var/www'), 'www/drupal'),
      array('/var/www/drupal', array('/extra', '/var/www'), 'www/drupal'),
      array('/var/www/drupal', array('/var/www', '/extra'), 'www/drupal'),
      array('/opt/other', array('/var/www'), '/opt/other'),
    );
  }

  /**
   * @param string $path
   * @param array $basePaths
   * @param string $expected
   * @dataProvider dataFormatPrettyPath
   */
  public function testFormatPrettyPath($path, $basePaths, $expected) {
    $fs = new Filesystem();
    $this->assertEquals($expected, $fs->formatPrettyPath($path, $basePaths));
  }

}
