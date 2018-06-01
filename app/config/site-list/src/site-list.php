<?php

/**
 * Render the main page.
 *
 * @param array|NULL $config
 * @param array $civibuild
 */
function sitelist_main($config, $civibuild) {
  $config = sitelist_config((array) $config);
  $sites = sitelist_read_all($civibuild['BLDDIR']);

  if (empty($_GET['filter'])) {
    echo sitelist_render('list-page.tpl.php', [
      'config' => $config,
      'sites' => $sites,
    ]);
  }
  else {
    $regex = sitelist_create_filter($_GET['filter']);
    echo sitelist_render('list-page.tpl.php', [
      'filter' => $_GET['filter'],
      'config' => $config,
      'sites' => sitelist_preg_grep_key($sites, $regex),
    ]);
  }
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
    if (empty($line) || $line{0} == '#') {
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
 * @param string $bldDir
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

    $sites[$name] = sitelist_read_sh($file);
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
