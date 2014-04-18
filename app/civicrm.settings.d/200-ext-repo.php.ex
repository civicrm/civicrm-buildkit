<?php
// This is an example which disables installation of extensions on all sites.

global $civicrm_setting;
$civicrm_setting['Extension Preferences']['ext_repo_url'] = false;
