<?php

// Work-around: CLI installer puts bad values in CIVICRM_UF_BASEURL
define('CIVICRM_UF_BASEURL', rtrim($civibuild['CMS_URL'], '/') . '/administrator/');
