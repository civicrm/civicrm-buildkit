<?php

global $civibuild, $settings;
// Example CMS_VERSIONs: '7', '7.23', '7.x', '8', '8.8', '8.x'. Note that the '8.x' case would mess up `version_compare()`.
if (empty($settings['file_private_path']) && isset($civibuild['CMS_VERSION']) && $civibuild['CMS_VERSION'][0] === '8') {
  $settings['file_private_path'] = $civibuild['PRIVATE_ROOT'] . DIRECTORY_SEPARATOR . $civibuild['DRUPAL_SITE_DIR'];
}
