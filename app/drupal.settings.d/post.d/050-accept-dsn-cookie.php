<?php
// When processing web-tests, the web-test may use a cookie to request specific DSN
if (isset($_COOKIE) && isset($_COOKIE['civiConsts'])) {
  $civiConsts = json_decode(($_COOKIE['civiConsts']), TRUE);
  $sig = md5(implode(';;', array($civiConsts['CIVICRM_DSN'], $civiConsts['CIVICRM_UF_DSN'], $GLOBALS['civibuild']['SITE_TOKEN'], $civiConsts['ts'])));
  if ($sig !== $civiConsts['sig'] || $civiConsts['ts'] + (6*60*60) < time()) {
    throw new Exception("Invalid cookie: civiConst");
  }

  if (!empty($civiConsts['CIVICRM_UF_DSN'])) {
    $uf_dsn = parse_url($civiConsts['CIVICRM_UF_DSN']);
    $GLOBALS['databases']['default']['default'] = array(
      'database' => trim($uf_dsn['path'], '/'),
      'username' => $uf_dsn['user'],
      'password' => $uf_dsn['pass'],
      'host' => $uf_dsn['host'],
      'port' => $uf_dsn['port'],
      'driver' => $uf_dsn['scheme'],
      'prefix' => '',
    );
  }
}
