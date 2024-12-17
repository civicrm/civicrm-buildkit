<?php

/**
 * Read a phpunit.xml.dist file. Add a new <testsuite> with a list of folders.
 */

if ($argc < 3) {
  fwrite(STDERR, "Usage: php add-suite.php SUITE-NAME FILES... < phpunit.xml.dist > phpunit.xml\n");
  fwrite(STDERR, "  SUITE-NAME:  Logical name of the test-suite (Ex 'phpunit-e2e')\n");
  fwrite(STDERR, "  FILES...:    List of test-files or test-folders to include in the suite\n");
  exit(1);
}

// Get the suite name and directories from command-line arguments
$suiteName = $argv[1];
$files = array_slice($argv, 2);

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
foreach ($files as $file) {
  if (is_dir($file)) {
    $dirElement = $xml->createElement('directory', $file);
    $testsuite->appendChild($dirElement);
  }
  elseif (preg_match(';Test\.php$;', $file)) {
    $fileElement = $xml->createElement('file', $file);
    $testsuite->appendChild($fileElement);
  }
  else {
    fprintf(STDERR, "Warning: Ignore requested file %s\n", $file);
  }
}

// Append the new <testsuite> to <testsuites>
$testsuites->appendChild($testsuite);

// Output the modified XML to STDOUT
echo $xml->saveXML();
