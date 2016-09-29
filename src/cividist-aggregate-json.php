<?php
$files = explode("\n", file_get_contents('php://stdin'));

$versions = array();
foreach ($files as $file) {
  if (empty($file)) continue;
  $name = basename(dirname($file));
  $versions[$name] = json_decode(file_get_contents($file), 1);
  $versions[$name] = strip_git_remote($versions[$name]);
  $versions[$name] = apply_url_prefix($versions[$name], "$name/");
}

echo json_encode($versions, defined('JSON_PRETTY_PRINT') ? JSON_PRETTY_PRINT : 0);

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