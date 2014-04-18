<?php

// This file is included in every copy of civicrm.settings.php

/**
 * Build a list of script in various script dirs. If two script dirs
 * define the same file, then only will be loaded. Scripts will be
 * sorted globally and executed in order.
 *
 * @param array<string> $dirs ordered from lowest to highest priority
 */
function _civibuild_find_scripts($dirs) {
  $files = array();
  foreach ($dirs as $dir) {
    $dir = realpath($dir);
    if (is_dir($dir)) {
      foreach ((array)glob("$dir/*.php") as $file) {
        $files[ basename($file) ] = $file;
      }
    }
  }
  ksort($files);
  return $files;
}

/**
 * @param array $civibuild some of the standard civibuild variables, eg
 *  - PRJDIR
 *  - SITE_NAME
 *  - SITE_TYPE
 *  - SITE_CONFIG_DIR
 *  - CIVI_SETTINGS
 */
function _civibuild_civicrm_settings($civibuild) {
  $files = _civibuild_find_scripts(array(
    // sorted from lowest priority to highest priority
    dirname(__DIR__) . '/app/civicrm.settings.d',
    '/etc/civicrm.settings.d',
    $civibuild['SITE_CONFIG_DIR'] . '/civicrm.settings.d',
    dirname($civibuild['CIVI_SETTINGS']) . '/civicrm.settings.d',
  ));
  foreach ($files as $file) {
    require_once $file;
  }
}
