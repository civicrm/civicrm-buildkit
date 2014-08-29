<?php

// This file is included in every copy of civicrm.settings.php and settings.php.

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
 * @param string $parentFile The context in which this is loaded (eg "/var/www/sites/example.com/civicrm.settings.php")
 * @param string $settingType eg "civicrm.settings.d" or "drupal.settings.d"
 * @param array $civibuild some of the standard civibuild variables, eg
 *  - PRJDIR
 *  - SITE_NAME
 *  - SITE_TYPE
 *  - SITE_CONFIG_DIR
 *  - CIVI_SETTINGS
 * @param string $phase 'pre' or 'post' (default is 'post' for backward compatibility)
 */
function _civibuild_settings($parentFile, $settingType, $civibuild, $phase = 'post') {
  $dirs = array(
    // sorted from lowest priority to highest priority
    dirname(__DIR__) . '/app/' . $settingType . "/{$phase}.d",
    $civibuild['SITE_CONFIG_DIR'] . '/' . $settingType . "/{$phase}.d",
    '/etc/' . $settingType . "/{$phase}.d",
    dirname($parentFile) . '/' . $settingType . "/{$phase}.d",
  );

  // backward compatibility - Scripts which aren't in pre.d or post.d are treated as post scripts
  if ($phase == 'post') {
    $dirs = array_merge($dirs,array(
      // sorted from lowest priority to highest priority
      dirname(__DIR__) . '/app/' . $settingType,
      $civibuild['SITE_CONFIG_DIR'] . '/' . $settingType,
      '/etc/' . $settingType,
      dirname($parentFile) . '/' . $settingType,
    ));
  }

  $files = _civibuild_find_scripts($dirs);
  foreach ($files as $file) {
    require_once $file;
  }
}
