<?php
// When processing web-tests, the web-test may use a cookie to request specific DSN
if (isset($_COOKIE) && isset($_COOKIE['civiConsts'])) {
  $civiConsts = json_decode(($_COOKIE['civiConsts']), TRUE);
  $sig = md5(implode(';;', array($civiConsts['CIVICRM_DSN'], $civiConsts['CIVICRM_UF_DSN'], $civibuild['SITE_TOKEN'], $civiConsts['ts'])));
  if ($sig !== $civiConsts['sig'] || $civiConsts['ts'] + (6*60*60) < time()) {
    throw new Exception("Invalid cookie: civiConst");
  }
  if (!empty($civiConsts['CIVICRM_DSN'])) {
    define('CIVICRM_DSN', $civiConsts['CIVICRM_DSN']);
  }
  if (!empty($civiConsts['CIVICRM_UF_DSN'])) {
    define('CIVICRM_UF_DSN', $civiConsts['CIVICRM_UF_DSN']);
  }
}
