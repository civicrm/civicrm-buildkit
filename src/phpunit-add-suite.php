<?php

/**
 * Read a phpunit.xml.dist file. Add a new <testsuite> with a list of folders.
 */

if ($argc < 3) {
  fwrite(STDERR, "Usage: php add-suite.php <suite-name> <directory1> [<directory2> ...] < phpunit.xml.dist > phpunit.xml\n");
  exit(1);
}

// Get the suite name and directories from command-line arguments
$suiteName = $argv[1];
$directories = array_slice($argv, 2);

// Load the XML template from STDIN
$xml = new DOMDocument();
$xml->preserveWhiteSpace = FALSE;
$xml->formatOutput = TRUE;
$xml->load('php://stdin');

// Locate the <testsuites> element
$xpath = new DOMXPath($xml);
$testsuites = $xpath->query('/phpunit/testsuites')->item(0);

if (!$testsuites) {
  fwrite(STDERR, "Error: <testsuites> element not found in the XML.\n");
  exit(1);
}

// Create the new <testsuite> element
$testsuite = $xml->createElement('testsuite');
$testsuite->setAttribute('name', $suiteName);

// Add each directory as a <directory> element within the new <testsuite>
foreach ($directories as $directory) {
  if (is_dir($directory)) {
    $dirElement = $xml->createElement('directory', $directory);
    $testsuite->appendChild($dirElement);
  }
}

// Append the new <testsuite> to <testsuites>
$testsuites->appendChild($testsuite);

// Output the modified XML to STDOUT
echo $xml->saveXML();
