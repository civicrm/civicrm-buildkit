<?php
// If the local system has setup a custom directory for publishing extensions and hasn't otherwise specified the
// the ext_repo_url, then set ext_repo_url.

global $civicrm_setting;
global $civibuild;
if (
  !isset($civicrm_setting['Extension Preferences']['ext_repo_url'])
  && file_exists($civibuild['PRJDIR'] . '/build/extdir/.extdir-url')
  && !file_exists($civibuild['PRJDIR'] . '/build/extdir/.extdir-no-auto')
) {
  $civicrm_setting['Extension Preferences']['ext_repo_url'] = trim(file_get_contents($civibuild['PRJDIR'] . '/build/extdir/.extdir-url'));
}
