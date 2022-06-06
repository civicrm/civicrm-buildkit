<?php

global $civibuild, $settings;
// Example CMS_VERSIONs: '7', '7.23', '7.x', '8', '8.3.4', '8.x', '^9'. Note that the '8.x' and `^9' case would mess up `version_compare()`.
$cmsMajorVer = ltrim(explode('.', $civibuild['CMS_VERSION'] ?? '')[0], '^~><=');
if ($cmsMajorVer && empty($settings['file_private_path']) && $cmsMajorVer >= 8) {
  $settings['file_private_path'] = $civibuild['PRIVATE_ROOT'] . DIRECTORY_SEPARATOR . $civibuild['DRUPAL_SITE_DIR'];
}
