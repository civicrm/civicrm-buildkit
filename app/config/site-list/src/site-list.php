<?php

/**
 * Render the main page.
 *
 * Example: Show all sites in HTML
 * /index.php
 *
 * Example: Show all sites in JSON
 * /index.php?format=application/json
 *
 * Example: Show all details of all sites in JSON (authentication required)
 * /index.php?format=application/json&token=abcd1234
 *
 * @param array|NULL $config
 * @param array $civibuild
 */
function sitelist_main($config, $civibuild) {
  $config = sitelist_config((array) $config);
  if (isset($config['bldDirs'])) {
    $sites = [];
    foreach ($config['bldDirs'] as $bldDir) {
      $sites = array_merge($sites, sitelist_read_all($bldDir));
    }
  }
  else {
    $sites = sitelist_read_all($civibuild['BLDDIR']);
  }

  if (!empty($config['moreSites'])) {
    $remotes = sitelist_fetch_all($config['moreSites']);
    $sites = array_merge($sites, $remotes);
  }

  ksort($sites);

  $view = sitelist_pick_view($_GET);

  if (empty($_GET['filter'])) {
    $view([
      'config' => $config,
      'sites' => $sites,
      'filter' => '',
    ]);
  }
  else {
    $regex = sitelist_create_filter($_GET['filter']);
    $view([
      'filter' => $_GET['filter'],
      'config' => $config,
      'sites' => sitelist_preg_grep_key($sites, $regex),
    ]);
  }
}

function sitelist_is_authenticated($token, $config) {
  if ($token === NULL) {
    return FALSE;
  }

  global $civibuild;
  if ($civibuild['SITE_TOKEN'] === $token) {
    return TRUE;
  }

  if (isset($config['site_token']) && $config['site_token'] === $token) {
    return TRUE;
  }

  throw new \RuntimeException("Incorrect token token");
}

/**
 * @return mixed
 */
function sitelist_pick_view($get) {
  if (empty($get['format'])) {
    return 'sitelist_view_html';
  }

  if ($get['format'] === 'text/html') {
    return 'sitelist_view_html';
  }

  if ($get['format'] === 'application/json') {
    return 'sitelist_view_json';
  }

  throw new \RuntimeException("Malformed format");
}

/**
 * Display the list as HTML.
 *
 * @param $p
 */
function sitelist_view_html($p) {
  echo sitelist_render('list-page.tpl.php', $p);
}

/**
 * Display the list as JSON.
 *
 * @param $p
 */
function sitelist_view_json($p) {
  header("Content-type: application/json");

  if (sitelist_is_authenticated(sitelist_get_token(), $p['config'])) {
    $sites = $p['sites'];
  }
  else {
    $sites = array_map(function ($site) use ($p) {
      return sitelist_array_subset($site, $p['config']['display']);
    }, $p['sites']);
  }

  echo json_encode($sites);
}

/**
 * Convert a filter expression to regex.
 *
 * @param string $filter
 *   Ex: 'dmaster'
 *   Ex: 'core-*-*'
 *   Ex: 'd*'
 * @return string
 *   Ex: '/^dmaster$/'
 *   Ex: '/^core-.*-.*$/'
 *   Ex: '/^d.*$/'
 */
function sitelist_create_filter($filter) {
  $regex = '/^' . preg_quote($filter, '/') . '$/';
  $regex = str_replace(
    preg_quote('*', '/'),
    '.*',
    $regex
  );
  return $regex;
}

/**
 * Render a template.
 *
 * @param string $_tpl_file
 *   Ex: 'my-view.tpl.php';
 * @param array $_tpl_data
 *   List of variables to import to the scope of the view.
 * @return string
 */
function sitelist_render($_tpl_file, $_tpl_data = array()) {
  $_tpl_file = __DIR__ . DIRECTORY_SEPARATOR . $_tpl_file;
  ob_start();
  extract($_tpl_data);
  include $_tpl_file;
  return ob_get_clean();
}

/**
 * Generate the overall configuration, including $values and any defaults.
 *
 * @return array
 *   A list of config options, such as:
 *   'about': string, displayable message about this server
 *   'display': array, with an ordered list of options; any of the following
 *     'ADMIN_USER'
 *     'ALL'
 *     'BUILD_TIME'
 *     'DEMO_USER'
 *     'CIVI_CORE'
 *     'CIVI_DB'
 *     'CMS_DB'
 *     'SITE_TYPE'
 *     'TEST_DB'
 *     'WEB_ROOT'
 */
function sitelist_config($values = array()) {
  $defaults = array(
    'title' => sprintf('Site list (%s)', gethostname()),
    'display' => ['ADMIN_USER', 'DEMO_USER', 'SITE_TYPE', 'BUILD_TIME'],
    'moreSites' => [],
  );
  global $sitelist;
  return array_merge($defaults, (array) $sitelist);
}

/**
 * Read a civibuild config file.
 *
 * @param string $shFile
 *   Ex: '/srv/buildkit/build/foobar.sh'
 * @return array
 *   List of stored config values.
 *   Ex: ['ADMIN_USER'=>'foo', 'ADMIN_PASS'=>'bar', ...].
 */
function sitelist_read_sh($shFile) {
  $lines = explode("\n", file_get_contents($shFile));
  $result = array();
  foreach ($lines as $line) {
    if (empty($line) || $line[0] == '#') {
      continue;
    }
    if (preg_match('/^([A-Z0-9_]+)=\"(.*)\"$/', $line, $matches)) {
      $result[$matches[1]] = stripcslashes($matches[2]);
    }
    else {
      throw new \RuntimeException("Malformed line [$line]");
    }
  }

  $result['BUILD_TIME'] = filemtime($shFile);
  return $result;
}

/**
 * Read metadata for all available sites.
 *
 * @param string|array $bldDir
 * @return array
 *   Ex: ['dmaster' => ['SITE_TYPE' => 'drupal-demo', ...]].
 */
function sitelist_read_all($bldDir) {
  $sites = array();
  $files = (array) glob($bldDir . DIRECTORY_SEPARATOR . '*.sh');
  foreach ($files as $file) {
    $name = preg_replace(';\.sh$;', '', basename($file));

    // Does the site appear to truly exist?
    if (!file_exists($bldDir . DIRECTORY_SEPARATOR . $name)) {
      continue;
    }

    $site = sitelist_read_sh($file);
    $domain = parse_url($site['CMS_URL'], PHP_URL_HOST);
    if ($port = parse_url($site['CMS_URL'], PHP_URL_PORT)) {
      $domain .= ':' . $port;
    }
    $sites[$domain] = $site;
  }
  return $sites;
}

function sitelist_preg_grep_key($arr, $regex) {
  $result = array();
  foreach ($arr as $k => $v) {
    if (preg_match($regex, $k)) {
      $result[$k] = $v;
    }
  }
  return $result;
}

function sitelist_array_subset($array, $keys) {
  $r = [];
  foreach ($keys as $key) {
    if (isset($array[$key])) {
      $r[$key] = $array[$key];
    }
  }
  return $r;
}

/**
 * @return string|null
 */
function sitelist_get_token() {
  if (!empty($_REQUEST['token'])) {
    return $_REQUEST['token'];
  }

  return NULL;
}

/**
 * @param array $siteList
 *   Array(string $siteUrl => string $siteToken).
 * @return array
 *   Array(string $siteDomain => array $siteDetails).
 */
function sitelist_fetch_all($siteList) {
  $sites = [];
  foreach ($siteList as $site => $siteToken) {
    $json = sitelist_send_http_post("$site/index.php?format=application/json", ['token' => $siteToken]);

    if (empty($json)) {
      throw new \RuntimeException("Failed to fetch list from $site: no response");
    }
    $remote = json_decode($json, 1);
    if ($remote === NULL) {
      throw new \RuntimeException("Failed to fetch list from $site: malformed json ($json)");
    }
    $sites = array_merge($sites, $remote);
  }

  return $sites;
}

/**
 * @param $url
 * @param $postParams
 * @return mixed
 */
function sitelist_send_http_post($url, $postParams) {
  $ch = curl_init();
  curl_setopt($ch, CURLOPT_URL, $url);
  curl_setopt($ch, CURLOPT_POST, 1);
  curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query($postParams));
  curl_setopt($ch, CURLOPT_RETURNTRANSFER, TRUE);
  $json = curl_exec($ch);
  curl_close($ch);
  return $json;
}
