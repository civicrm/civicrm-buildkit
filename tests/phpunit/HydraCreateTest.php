<?php

use \Civi\Civibuild\ProcessUtil;

/**
 * Class HydraCreateTest
 *
 * Execute "hydra create" and ensure it produces several websites.
 */
class HydraCreateTest extends \Civi\Civibuild\CivibuildTestCase {

  /**
   * Create a test instance name Civibuild-test
   * (assumes no one will have created such an instance)
   */
  public function testBasic() {
    $escapedDir = escapeshellarg(__DIR__ . '');
    $options = '--prefix hydratest- --url-template ' . escapeshellarg('http://%SITE_NAME%.localhost');

    ProcessUtil::runOk($this->cmd("hydra destroy $options"));

    $result = ProcessUtil::runOk($this->cmd("hydra create $options $escapedDir/dummy-tarballs/*"));

    $this->assertFilesRegex(array(
      $this->getAbsPath('hydratest-backdrop', 'modules/civicrm/README.txt') => ';civicrm-core plus civicrm-backdrop@1.x;',
      $this->getAbsPath('hydratest-drupal', 'sites/all/modules/civicrm/README.txt') => ';civicrm-core plus civicrm-drupal@7.x;',
      $this->getAbsPath('hydratest-wp', 'wp-content/plugins/civicrm/README.txt') => ';civicrm-core plus civicrm-wordpress;',
    ));

    $builds = array('hydratest-backdrop', 'hydratest-drupal', 'hydratest-wp');
    foreach ($builds as $build) {
      $this->assertRegExp('; - CMS_ROOT: [^\n]+/build/' . preg_quote($build, ';') . ';', $result->getOutput());
      $this->assertRegExp('; - CIVI_DB_DSN: mysql://.*:.*@.*/.*;', $result->getOutput());
      $configFile = $this->getPrjDir() . "/build/{$build}.sh";
      $this->assertFileExists($configFile);
      $config = file_get_contents($configFile);
      $this->assertRegExp(';CMS_ROOT=[^\n]+/build/' . preg_quote($build, ';') . ';', $config);
      $this->assertRegExp(';CIVI_DB_DSN=\"?mysql://.*:.*@.*/.*\"?;', $config);
    }
  }

  /**
   * Assert that a batch of files matches the regular expressions.
   * @param array $files
   *   Ex: $files['/etc/hosts'] = ';127\.0\.0\.1.*localhost;'
   */
  public function assertFilesRegex($files) {
    foreach ($files as $file => $regex) {
      $this->assertFileExists($file, "Check that $file exists");
      $this->assertRegExp($regex, file_get_contents($file), "Check that file $file matches $regex");
    }
  }

}
