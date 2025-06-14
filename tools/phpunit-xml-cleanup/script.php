#!/usr/bin/env php
<?php
## When outputting JUnit XML files with backtraces, phpunit sometimes
## generates invalid markup.  This is an ugly work-around to fix the
## scenario wherein Civi's value-separator (\0001) is part of the backtrace.

$sep = "";

$files = $argv;
array_shift($files);

foreach ($files as $file) {
  $content = file_get_contents($file);
  #$content = str_replace($sep, '&#x0001;', $content);
  $content = str_replace($sep, '', $content);
  $content = preg_replace('/(<testsuite.*) fullPackage="[^"]+" /', '$1 ', $content);
  $content = preg_replace('/(<testsuite.*) subpackage="[^"]+" /', '$1 ', $content);
  $content = preg_replace('/(<testsuite.*) namespace="[^"]+" /', '$1 ', $content);
  $content = preg_replace('/(<testsuite.*) warnings="[^"]+" /', '$1 ', $content);
  if (isXmlEmpty($content)) {
    $content = verbosePlaceholder();
  }
  file_put_contents($file, $content);
}

function isXmlEmpty($content) {
  $xmlIterator = new SimpleXMLIterator( $content);
  for ($xmlIterator->rewind(); $xmlIterator->valid(); $xmlIterator->next()) {
    return FALSE;
  }
  return TRUE;
}

function verbosePlaceholder() {
  // Jenkins is quite persnickity.
  $lines = [
    '<?xml version="1.0" encoding="UTF-8"?>',
    '<testsuites>',
    '  <testsuite name="Placeholder" tests="0" assertions="0" errors="0" warnings="0" failures="0" skipped="0" time="0">',
    '  </testsuite>',
    '</testsuites>',
  ];
  return implode("\n", $lines);
}
