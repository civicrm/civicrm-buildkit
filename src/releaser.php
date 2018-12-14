#!/usr/bin/env php
<?php

###############################################################################
## Bootstrap
ini_set('display_errors', 1);

###############################################################################

function usage($error = FALSE) {
  echo "about: Publish a release.\n";
  echo "usage: releaser <json-url> [tasks] [options]\n";
  echo "  Tasks:\n";
  echo "    --get                 Download an RC or nightly build\n";
  echo "    --sign                Generate checksum and GPG signature\n";
  echo "    --tag                 Generate and push git tags\n";
  echo "    --publish             Send build to primary download service\n";
  echo "    --esr-publish         Send build to ESR download service\n";
  echo "    --clean               Delete any temp files\n";
  echo "  Options:\n";
  echo "     -f                   Force, even if it replaces existing items\n";
  echo "     -n                   No pushing. Dry-run.\n";
  echo "     --git-remote <n>     Name of the git remote (Default: origin)\n";
  echo "     --gpg-key <n>        Name of the GPG signing key (Default: 7A1E75CB)\n";
  echo "example: releaser gs://civicrm-build/4.7.19-rc/civicrm-4.7.19-201705020430.json --get --sign\n";
  if ($error) {
    echo "error: $error\n";
  }
}

###############################################################################

/**
 * @param array $argv
 *   List of command line arguments.
 * @return int
 *   Exit code
 */
function main($argv) {
  array_shift($argv);

  $stagingBaseDir = getenv('RELEASE_TMPDIR');
  if (!$stagingBaseDir || !file_exists($stagingBaseDir)) {
    usage('Environment variable RELEASE_TMPDIR should reference a local data dir');
    return 1;
  }

  $tasks = array();
  $versionSpecs = array();
  $options = array(
    'force' => FALSE,
    'git-remote' => 'origin',
    'gpg-key' => '7A1E75CB',
    'dry-run' => FALSE,
  );

  while (!empty($argv)) {
    $expr = array_shift($argv);

    switch ($expr) {
      case '--get':
        $tasks[] = 'main_get';
        break;

      case '--tag':
        $tasks[] = 'main_tag';
        break;

      case '--sign':
        $tasks[] = 'main_sign';
        break;

      case '--publish':
        $tasks[] = 'main_publish';
        break;

      case '--esr-publish':
        $tasks[] = 'main_esr_publish';
        break;

      case '--clean':
        $tasks[] = 'main_clean';
        break;

      case '-f':
        $options['force'] = TRUE;
        break;

      case '-n':
        $options['dry-run'] = TRUE;
        break;

      case '--git-remote':
        $options['git-remote'] = array_shift($argv);
        break;

      case '--gpg-key':
        $options['gpg-key'] = array_shfit($argv);
        break;

      default:
        if (preg_match(';^(gs://civicrm-build/.*)/civicrm-(.+)-([0-9]+)\.json;',
          $expr, $matches)) {
          $versionSpecs[] = array(
            'json' => $expr,
            'stagingDir' => $stagingBaseDir . '/' . md5($expr) . '/' . $matches[2],
            'gitDir' => getcwd(),
            'prefix' => $matches[1],
            'version' => $matches[2],
            'timestamp' => $matches[3],
          );
        }
        else {
          usage("Unrecognized option or URL: $expr");
          return 2;
        }
        break;
    }
  }

  if (empty($versionSpecs) || empty($tasks)) {
    usage('Must specify at least one task and one JSON URL');
    return 3;
  }

  foreach ($versionSpecs as $versionSpec) {
    util_info(sprintf("# Processing v%s (%s)", $versionSpec['version'],
      $versionSpec['json']));
    util_info(sprintf("# Staging directory is %s", $versionSpec['stagingDir']));
    util_info(sprintf("# Local git tree is %s", $versionSpec['gitDir']));
    if (!file_exists($versionSpec['stagingDir'])) {
      util_info('## Make temp dir: ' . $versionSpec['stagingDir']);
      mkdir($versionSpec['stagingDir'], 0777, TRUE);
    }
    foreach ($tasks as $task) {
      $task($versionSpec, $options);
    }
  }

  return 0;
}

###############################################################################

/**
 * Get the RC or nightly build
 *
 * @param array $versionSpec
 */
function main_get($versionSpec, $options) {
  util_info('## Get the RC or nightly build');
  $fileUrls = gsutil_ls($versionSpec['prefix'] . '/civicrm-*' . $versionSpec['version'] . '*' . $versionSpec['timestamp'] . '*');
  foreach ($fileUrls as $fileUrl) {
    $filePath = $versionSpec['stagingDir'] . '/' . str_replace('-' . $versionSpec['timestamp'],
        '', basename($fileUrl));
    if (file_exists($filePath)) {
      if (empty($options['force'])) {
        util_warn("[[Skipped item: $filePath already exists]]");
        continue;
      }
      util_warn("[[Overwrite $filePath]]");
    }
    gsutil_cp($fileUrl, $filePath);
  }
}

/**
 * Generate checksum and GPG signature
 * @param array $versionSpec
 */
function main_sign($versionSpec, $options) {
  util_info('## Generate checksum and GPG signature');

  //  $passphrase = getenv('RELEASE_PASS');
  //  if (empty($passphrase)) {throw new \Exception("Cannot generate signatures. Please set RELEASE_PASS.");}
  //  $command = sprintf("echo %s | gpg -b --armor --batch --passphrase-fd 0 -u %s --sign %s");

  $md5File = 'civicrm-' . $versionSpec['version'] . '.MD5SUMS';
  $sha256File = 'civicrm-' . $versionSpec['version'] . '.SHA256SUMS';

  util_exec($versionSpec['stagingDir'],
    sprintf("md5sum *.tar.gz *.tgz *.zip *.json > %s", escapeshellarg($md5File)));
  util_exec($versionSpec['stagingDir'],
    sprintf("sha256sum *.tar.gz *.tgz *.zip *.json > %s", escapeshellarg($sha256File)));

  util_exec($versionSpec['stagingDir'],
    sprintf("gpg -b --armor -u %s --sign %s",
      escapeshellarg($options['gpg-key']), escapeshellarg($md5File)));
  util_exec($versionSpec['stagingDir'],
    sprintf("gpg -b --armor -u %s --sign %s",
      escapeshellarg($options['gpg-key']), escapeshellarg($sha256File)));
}

/**
 * Generate and push git tags.
 *
 * @param array $versionSpec
 */
function main_tag($versionSpec, $options) {
  util_info('## Generate and push git tags');
  $jsonFile = sprintf("%s/civicrm-%s.json",
    $versionSpec['stagingDir'], $versionSpec['version']);
  $versionJson = json_decode(file_get_contents($jsonFile), 1);
  $newTags = main_tag_plan($versionSpec, $versionJson);
  $force = $options['force'] ? '-f' : '';

  // Do all the local ops first. Progress toward more risky/enduring.

  foreach ($newTags as $todo) {
    git($todo['path'],
      sprintf("git fetch %s", escapeshellarg($options['git-remote'])));
  }

  foreach ($newTags as $todo) {
    git($todo['path'],
      sprintf("git tag %s %s %s", $force,
        escapeshellarg($todo['tag']), escapeshellarg($todo['commit'])));
  }

  if (empty($options['dry-run'])) {
    foreach ($newTags as $todo) {
      git($todo['path'], sprintf("git push %s %s %s", escapeshellarg($options['git-remote']), $force, escapeshellarg($todo['tag'])));
    }
  }
}

/**
 * Send build to primary download service.
 *
 * @param array $versionSpec
 */
function main_publish($versionSpec, $options) {
  util_info('## Send build to primary download service');
  $dry = $options['dry-run'] ? '-n' : '';
  util_passthru_ok(sprintf("gsutil rsync $dry %s/ %s/",
    escapeshellarg($versionSpec['stagingDir']),
    escapeshellarg('gs://civicrm/civicrm-stable/' . $versionSpec['version'])
  ));
  util_passthru_ok(sprintf("rsync -va $dry %s/ %s/",
    escapeshellarg($versionSpec['stagingDir']),
    escapeshellarg('civicrm@frs.sourceforge.net:/home/frs/project/civicrm/civicrm-stable/' . $versionSpec['version'])
  ));
}

/**
 * Send build to ESR download service.
 *
 * @param array $versionSpec
 */
function main_esr_publish($versionSpec, $options) {
  util_info('## Send build to primary download service');
  $dry = $options['dry-run'] ? '-n' : '';
  util_passthru_ok(sprintf("gsutil -m rsync $dry %s/ %s/",
    escapeshellarg($versionSpec['stagingDir']),
    escapeshellarg('gs://civicrm-private/civicrm-esr/' . $versionSpec['version'])
  ));
}

/**
 * Delete any temp files.
 *
 * @param array $versionSpec
 */
function main_clean($versionSpec, $options) {
  util_info('## Delete any temp files');
  if (file_exists($versionSpec['stagingDir'])) {
    $parentDir = dirname($versionSpec['stagingDir']);
    $childDir = basename($versionSpec['stagingDir']);
    util_exec($parentDir, sprintf("rm -rf %s", escapeshellarg($childDir)));
  }
}

###############################################################################

/**
 * Build a list of tags that should exist.
 *
 * @param array $versionSpec
 * @param array $versionJson
 * @return array
 *   Each item has:
 *     - path: string, the file path to the local repo
 *     - tag: string, the name of a new git tag
 *     - commit: string, git sha1 hash
 * @throws \Exception
 */
function main_tag_plan($versionSpec, $versionJson) {
  $repoPaths = array(
    "civicrm-drupal" => $versionSpec['gitDir'] . "/drupal",
    "civicrm-backdrop" => $versionSpec['gitDir'] . "/backdrop",
    "civicrm-core" => $versionSpec['gitDir'],
    "civicrm-packages" => $versionSpec['gitDir'] . "/packages",
    "civicrm-wordpress" => $versionSpec['gitDir'] . "/WordPress",
    "civicrm-joomla" => $versionSpec['gitDir'] . "/joomla",
  );
  $todos = array();
  foreach ($versionJson['git'] as $repoDesc => $repo) {
    // Ex: $repoName: "civicrm-drupal@7.x" or "civicrm-core".
    if (strpos($repoDesc, '@') !== FALSE) {
      list ($repoName, $tagPrefix) = explode('@', $repoDesc);
      $tagName = $tagPrefix . '-' . $versionSpec['version'];
    }
    else {
      $repoName = $repoDesc;
      $tagName = $versionSpec['version'];
    }
    if (!isset($repoPaths[$repoName])) {
      throw new \Exception("Failed to determine path for repo $repoName");
    }
    if (!file_exists($repoPaths[$repoName])) {
      throw new \Exception("Failed to find $repoName in \"$repoPaths[$repoName]\". Did you run this command in a CiviCRM source tree?");
    }
    if (empty($repo['commit'])) {
      throw new \Exception("Failed to determine commit for $repoName");
    }
    $todos[$repoDesc] = array(
      'repo' => $repoDesc,
      'path' => $repoPaths[$repoName],
      'tag' => $tagName,
      'commit' => $repo['commit'],
    );
  }
  return $todos;
}

###############################################################################

function gsutil_ls($arg) {
  $command = "gsutil ls " . escapeshellarg($arg);
  util_exec(NULL, $command, $lines, $result);
  if ($result !== 0) {
    throw new \Exception("Command failed: \"$command\": " .
      implode("\n", $lines));
  }
  foreach ($lines as $line) {
    if (!preg_match(';^gs://;', $line)) {
      throw new \Exception("Command \"$command\" returned invalid line \"$line\"");
    }
  }
  return $lines;
}

function gsutil_cp($src, $dest) {
  util_info("Copy \"$src\" to \"$dest\"");
  $command = sprintf("gsutil cp %s %s", escapeshellarg($src),
    escapeshellarg($dest));
  util_exec(NULL, $command, $lines, $result);
  if ($result !== 0) {
    throw new \Exception("Command failed: \"$command\": " . implode("\n",
        $lines));
  }
}

###############################################################################

/**
 * Call a git subcommand.
 *
 * @param string $path
 *   Ex: /var/www/sites/all/modules/civicrm.
 * @param string $command
 *   Ex: git fetch origin
 * @throws \Exception
 */
function git($path, $command) {
  util_exec($path, $command, $lines, $result);

  if ($result !== 0) {
    throw new \Exception("Command failed in \"$path\": \"$command\": " .
      implode("\n", $lines));
  }
}

###############################################################################

function util_exec($cwd, $command, &$lines = NULL, &$result = NULL) {
  if ($cwd) {
    util_info("\$ $command [[in $cwd]]");
    $oldCwd = getcwd();
    chdir($cwd);
    exec($command, $lines, $result);
    chdir($oldCwd);
  }
  else {
    util_info("\$ $command");
    exec($command, $lines, $result);
  }
}

function util_passthru_ok($command, &$result = NULL) {
  util_info("\$ $command");
  passthru($command, $result);
  if ($result !== 0) {
    throw new \Exception("Command failed: \"$command\"");
  }
}


function util_info($message) {
  echo "$message\n";
}

function util_warn($message) {
  fwrite(STDERR, "WARNING: $message\n");
}

###############################################################################
exit(main($argv));
