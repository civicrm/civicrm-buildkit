<?php
$baseUrl = !empty($argv[1]) ? $argv[1] : '.';
$files = explode("\n", file_get_contents('php://stdin'));

$versions = array();
foreach ($files as $file) {
  if (empty($file)) {
    continue;
  }
  $name = basename(dirname($file));
  $versions[$name] = json_decode(file_get_contents($file), 1);
  $versions[$name] = strip_git_remote($versions[$name]);
  $versions[$name] = regen_tar_urls($versions[$name], dirname($file), "$baseUrl/$name");
}

$jsonOptions = 0;
if (defined('JSON_PRETTY_PRINT')) $jsonOptions |= JSON_PRETTY_PRINT;
if (defined('JSON_UNESCAPED_SLASHES')) $jsonOptions |= JSON_UNESCAPED_SLASHES;
echo json_encode($versions, $jsonOptions);

##############################

/**
 * Simplify git branch names, changing "refs/remotes/origin/master" to
 * to just "master".
 */
function strip_git_remote($data) {
  foreach (array_keys($data['git']) as $key) {
    $data['git'][$key] = str_replace('refs/remotes/origin/', '', $data['git'][$key]);
  }
  return $data;
}

/**
 * Update URLs, changing "foo.zip" to "subdir/foo.zip".
 */
function apply_url_prefix($data, $prefix) {
  foreach (array_keys($data['tar']) as $key) {
    $data['tar'][$key] = $prefix . $data['tar'][$key];
  }
  return $data;
}

/**
 * Update URLs, changing "foo.zip" to "subdir/foo.zip".
 * @param array $data
 *   Full description of the release (version, git commits, tar files, etc)
 * @param string $localPath
 *   The local path of the released files
 * @param string $remoteUrl
 *   The remote URL of the released files.
 * @return array
 *   Updated version of $data.
 */
function regen_tar_urls($data, $localPath, $remoteUrl) {
  $files = (array) glob("$localPath/civicrm-*");
  $tarUrls = array();
  foreach ($files as $file) {
    $basename = basename($file);
    $key = classify_tar_file($basename);
    if ($key) {
      $tarUrls[$key] = $remoteUrl . '/' . $basename;
    }
  }
  $data['tar'] = $tarUrls;

  return $data;
}

/**
 * @param string $basename
 *   Ex: 'civicrm-4.7.13-drupal.tar.gz', 'civicrm-4.7.13-wordpress-20160901.zip'.
 * @return string
 *   Ex: 'Drupal', 'WordPress'
 */
function classify_tar_file($basename) {
  switch (TRUE) {
    case (boolean) preg_match(';civicrm-[\d\.]+-drupal6(\-\d+)?.tar.gz;', $basename);
      return 'Drupal6';

    case (boolean) preg_match(';civicrm-[\d\.]+-drupal(\-\d+)?.tar.gz;', $basename);
      return 'Drupal';

    case (boolean) preg_match(';civicrm-[\d\.]+-backdrop(\-unstable)?(|\-\d+)?.tar.gz;', $basename);
      return 'Backdrop';

    case (boolean) preg_match(';civicrm-[\d\.]+-joomla(\-\d+)?.zip;', $basename);
      return 'Joomla';

    case (boolean) preg_match(';civicrm-[\d\.]+-wordpress(\-\d+)?.zip;', $basename);
      return 'WordPress';

    case (boolean) preg_match(';civicrm-[\d\.]+-l10n(\-\d+)?.tar.gz;', $basename);
      return 'L10n';

    default:
      return NULL;

  }
}
