#!/usr/bin/env php
<?php

// 1. Parse Options and Flags
$opts = getopt('f:', ['pipe']);
$filename = $opts['f'] ?? NULL;
$isPipe = isset($opts['pipe']);

// Clean up argv to extract the command (get, set, list, delete) and its arguments
$args = $argv;
// remove script name
array_shift($args);
$filteredArgs = [];
$skipNext = FALSE;

foreach ($args as $i => $arg) {
  if ($skipNext) {
    $skipNext = FALSE; continue;
  }
  if ($arg === '-f') {
    $skipNext = TRUE; continue;
  }
  if (str_starts_with($arg, '-f') || $arg === '--pipe') {
    continue;
  }
  $filteredArgs[] = $arg;
}

$command = $filteredArgs[0] ?? 'help';
$payload = array_slice($filteredArgs, 1);

/**
 * Helper to write to stderr so stdout stays clean for XML piping
 */
function log_status($msg) {
  fwrite(STDERR, $msg . PHP_EOL);
}

// 2. Resolve Input Source
$dom = new DOMDocument();
$dom->preserveWhiteSpace = TRUE;
$dom->formatOutput = TRUE;

if ($isPipe) {
  $input = file_get_contents('php://stdin');
  if (empty($input)) {
    fwrite(STDERR, "Error: stdin is empty.\n");
    exit(1);
  }
  if (!@$dom->loadXML($input)) {
    fwrite(STDERR, "Error: Failed to parse XML from stdin.\n");
    exit(1);
  }
}
else {
  if (!$filename) {
    if (file_exists('phpunit.xml')) {
      $filename = 'phpunit.xml';
    }
    elseif (file_exists('phpunit.xml.dist')) {
      $filename = 'phpunit.xml.dist';
    }
    else {
      fwrite(STDERR, "Error: No phpunit.xml or phpunit.xml.dist found.\n");
      exit(1);
    }
  }
  if (!file_exists($filename) || !@$dom->load($filename)) {
    fwrite(STDERR, "Error: Could not load file '$filename'.\n");
    exit(1);
  }
}

$root = $dom->documentElement;

// 3. Execute Commands
switch ($command) {
  case 'list':
    foreach ($root->attributes as $attr) {
      printf("%-35s : %s\n", $attr->nodeName, $attr->nodeValue);
    }
    break;

  case 'get':
    $key = $payload[0] ?? NULL;
    if (!$key) {
      exit(fwrite(STDERR, "Usage: phpunit-config get [KEY]\n") * 0 + 1);
    }
    if ($root->hasAttribute($key)) {
      echo $root->getAttribute($key) . PHP_EOL;
    }
    else {
      fwrite(STDERR, "Attribute '$key' not found.\n");
      exit(1);
    }
    break;

  case 'set':
    if (empty($payload)) {
      exit(fwrite(STDERR, "Usage: phpunit-config set [KEY=VALUE...]\n") * 0 + 1);
    }
    foreach ($payload as $pair) {
      if (strpos($pair, '=') === FALSE) {
        continue;
      }
      [$key, $value] = explode('=', $pair, 2);
      $root->setAttribute($key, $value);
      log_status("Updated: $key=\"$value\"");
    }
    echo ($isPipe) ? $dom->saveXML() : $dom->save($filename);
    break;

  case 'delete':
    if (empty($payload)) {
      exit(fwrite(STDERR, "Usage: phpunit-config delete [KEY...]\n") * 0 + 1);
    }
    foreach ($payload as $key) {
      if ($root->hasAttribute($key)) {
        $root->removeAttribute($key);
        log_status("Deleted: $key");
      }
    }
    echo ($isPipe) ? $dom->saveXML() : $dom->save($filename);
    break;

  default:
    echo "Usage:\n";
    echo "  phpunit-config list   [-f FILE | --pipe]\n";
    echo "  phpunit-config get    [-f FILE | --pipe] [KEY]\n";
    echo "  phpunit-config set    [-f FILE | --pipe] [KEY=VALUE...]\n";
    echo "  phpunit-config delete [-f FILE | --pipe] [KEY...]\n";
    break;
}
