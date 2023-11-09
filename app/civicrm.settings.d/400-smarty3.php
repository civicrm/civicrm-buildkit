<?php

if (!isset($GLOBALS['_CV']) && isset($GLOBALS['civicrm_paths']) && !empty($GLOBALS['civicrm_paths']['civicrm.packages'])) {
  $packages_path = $GLOBALS['civicrm_paths']['civicrm.packages']['path'];
}
elseif (!isset($GLOBALS['_CV'])) {
  return;
}
else {
  switch($GLOBALS['_CV']['CIVI_UF']) {
   case 'Drupal':
     case 'Backdrop':
    case 'WordPress':
    case 'Standalone':
    case 'Joomla':
      $packages_path = $GLOBALS['_CV']['CIVI_CORE'] . DIRECTORY_SEPARATOR . 'packages';
      break;

    case 'Drupal8':
      $packages_path = dirname($GLOBALS['_CV']['CIVI_CORE']) . DIRECTORY_SEPARATOR . 'civicrm-packages';
      break;

  }
}

if (getenv('SMARTY3_ENABLE') && file_exists($packages_path . DIRECTORY_SEPARATOR . 'smarty3' . DIRECTORY_SEPARATOR . 'vendor' . DIRECTORY_SEPARATOR . 'autoload.php') && !defined('CIVICRM_SMARTY3_AUTOLOAD_PATH')) {
  define('CIVICRM_SMARTY3_AUTOLOAD_PATH', $packages_path . DIRECTORY_SEPARATOR . 'smarty3' . DIRECTORY_SEPARATOR . 'vendor' . DIRECTORY_SEPARATOR . 'autoload.php');
}
