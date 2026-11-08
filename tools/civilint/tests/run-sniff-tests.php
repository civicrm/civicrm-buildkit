#!/usr/bin/env php
<?php

/**
 * Runs each sniff over its fixture in tests/phpcs/<Category>/<Sniff>.inc or
 * <Sniff>.entityType.php and compares the findings per line with <Sniff>.expected.php.
 */

$root = dirname(__DIR__);
$fixtures = array_merge(glob(__DIR__ . '/phpcs/*/*.inc'), glob(__DIR__ . '/phpcs/*/*.entityType.php'));
if (!$fixtures) {
  fwrite(STDERR, "No fixtures found\n");
  exit(2);
}

$failed = FALSE;
foreach ($fixtures as $fixture) {
  $sniff = explode('.', basename($fixture))[0];
  $code = 'CiviCRM.' . basename(dirname($fixture)) . '.' . $sniff;
  $command = sprintf('%s %s --standard=%s --sniffs=%s --report=json %s',
    escapeshellarg(PHP_BINARY), escapeshellarg("$root/bin/phpcs"),
    escapeshellarg("$root/phpcs/CiviCRM"), escapeshellarg($code), escapeshellarg($fixture));
  $report = json_decode((string) shell_exec($command), TRUE);
  if (!isset($report['files'][$fixture])) {
    fwrite(STDERR, "$code: phpcs did not report on the fixture\n");
    exit(2);
  }

  $actual = ['errors' => [], 'warnings' => []];
  foreach ($report['files'][$fixture]['messages'] as $message) {
    $type = $message['type'] === 'ERROR' ? 'errors' : 'warnings';
    $actual[$type][$message['line']] = ($actual[$type][$message['line']] ?? 0) + 1;
  }

  $expected = require dirname($fixture) . "/$sniff.expected.php";
  foreach (['errors', 'warnings'] as $type) {
    foreach (array_keys($expected[$type] + $actual[$type]) as $line) {
      $want = $expected[$type][$line] ?? 0;
      $got = $actual[$type][$line] ?? 0;
      if ($want !== $got) {
        $failed = TRUE;
        echo "$code line $line: expected $want $type, got $got\n";
      }
    }
  }
  echo "$code: checked " . count($report['files'][$fixture]['messages']) . " findings\n";
}

exit($failed ? 1 : 0);
