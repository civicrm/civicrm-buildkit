<?php

/**
 * Run "civibuild show" and parse the utput
 *
 * @param string $buildName
 * @return array
 */
function civibuild_show($buildName) {
  $cmd = sprintf('civibuild show %s --full', escapeshellarg($buildName));
  $data = `$cmd`;
  $lines = explode("\n", $data);
  $result = array();
  foreach ($lines as $line) {
    if (preg_match('/^ - ([A-Z0-9_]+): (.*)$/', $line, $matches)) {
      $result[$matches[1]] = $matches[2];
    }
  }
  // /Users/totten/bknix/build/dmastzer
  if (empty($result) || empty($result['WEB_ROOT']) || !file_exists($result['WEB_ROOT'])) {
    throw new \Exception("Failed to find any data for $buildName");
  }
  return $result;
}
