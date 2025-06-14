#!/usr/bin/env php
<?php

function usage() {
  global $argv;
  echo "Usage: {$argv[0]}  [toolnames...]\n";
  echo "Example: {$argv[0]} forkify civicredits\n";
}

function fatal($message) {
  fwrite(STDERR, "ERROR: $message\n");
  usage();
  exit(2);
}

function getFileChecksum($file) {
  return file_exists($file) ? hash_file('sha256', $file) : '';
}

function main(array $argv): void {
  $prjDir = dirname(__DIR__);
  if (!is_dir("$prjDir/app")) {
    fatal("Invalid project dir");
  }

  $binDir = "$prjDir/bin";

  $tools = array_slice($argv, 1);
  if (empty($tools)) {
    fatal("No tools specified\n");
    // For the moment, it's best if composer.json has an explicit list of the tools.
    // Why? Because `civi-download-tools` will only autorun `composer` if the main `composer.json` has changed.

    // $toolsDir = "$prjDir/tools";
    // $tools = array_filter(scandir($toolsDir), function ($entry) use ($toolsDir) {
    //   return $entry[0] !== '.' && is_dir("$toolsDir/$entry");
    // });
  }

  foreach ($tools as $tool) {
    $toolDir = "$prjDir/tools/$tool";
    if (!is_dir($toolDir) || !preg_match(';^[-_\w]+$;', $tool)) {
      fatal("Invalid or missing tool directory: $toolDir\n");
      continue;
    }

    if (file_exists("$toolDir/composer.json")) {
      $checksumFile = "$toolDir/.composer.lock.last-checksum";
      $currentChecksum = getFileChecksum("$toolDir/composer.json") . '-' . getFileChecksum("$toolDir/composer.lock");
      $previousChecksum = is_file($checksumFile) ? trim(file_get_contents($checksumFile)) : '';

      if ($currentChecksum !== $previousChecksum || !file_exists("$toolDir/vendor/autoload.php")) {
        $cmd1 = "cd " . escapeshellarg($toolDir) . " && composer install --no-interaction";
        system($cmd1, $retval1);
        if ($retval1 !== 0) {
          fatal("Error: composer install failed for $tool\n");
        }

        file_put_contents($checksumFile, $currentChecksum);
      }
    }

    if (file_exists("$toolDir/run.php")) {
      createSymlink("$toolDir/run.php", "$binDir/$tool");
    }
    elseif (file_exists("$toolDir/bin/$tool")) {
      createSymlink("$toolDir/bin/$tool", "$binDir/$tool");
    }
    else {
      throw new \RuntimeException("$toolDir does not contain a main script");
    }
  }
}

function createSymlink(string $target, string $link): void {
  if (!is_dir(dirname($link))) {
    mkdir(dirname($link), 0777, TRUE);
  }

  if (file_exists($link) || is_link($link)) {
    unlink($link);
  }

  symlink($target, $link);
}

main($argv);
