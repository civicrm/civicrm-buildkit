<?php
#!require clippy/std: ~0.4.6

###############################################################################
## Bootstrap
namespace Clippy;

use GuzzleHttp\HandlerStack;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\Console\Style\SymfonyStyle;

$c = clippy()->register(plugins());

###############################################################################
## Services / computed data

$c['gpg'] = function(Credentials $cred): \Crypt_GPG {
  // It's easier to sign multiple files if we use Crypt_GPG wrapper API.
  #!require pear/crypt_gpg: ~1.6.4
  $gpg = new \Crypt_GPG(['binary' => trim(`which gpg`)]);
  $gpg->addSignKey($cred->get('GPG_KEY'), $cred->get('GPG_PASSPHRASE'));
  return $gpg;
};


$c['versionSpec'] = function (InputInterface $input) {
  $stagingBaseDir = getenv('RELEASE_TMPDIR');
  assertThat($stagingBaseDir && file_exists($stagingBaseDir), 'Environment variable RELEASE_TMPDIR should reference a local data dir');

  $jsonUrl = $input->getArgument('json-url');
  // ex: gs://civicrm-build/5.54/civicrm-5.54.2-202211050234.json
  // ex: gs://civicrm-build/5.51-security/civicrm-5.51.3-202211032104.json
  if (preg_match(';^(gs://civicrm-build/.*)/civicrm-(.+)-([0-9]+)\.json;', $jsonUrl, $m)) {
    return [
      'json' => $jsonUrl,
      'stagingDir' => $stagingBaseDir . '/' . md5($jsonUrl) . '/' . $m[2],
      'gitDir' => getcwd(),
      'prefix' => $m[1],
      'version' => $m[2],
      'timestamp' => $m[3],
    ];
  }

  // ex: gs://civicrm/civicrm-stable/5.51.0/civicrm-5.51.0.json
  if (preg_match(';^(gs://civicrm/civicrm-stable/.*)/civicrm-(.+)\.json;', $jsonUrl, $m)) {
    return [
      'json' => $jsonUrl,
      'stagingDir' => $stagingBaseDir . '/' . md5($jsonUrl) . '/' . $m[2],
      'gitDir' => getcwd(),
      'prefix' => $m[1],
      'version' => $m[2],
      'timestamp' => NULL,
    ];
  }

  throw new \Exception("Malformed JSON URL");
};

$c['runner'] = $c->autowiredObject(new class() {

  /**
   * @var \Symfony\Component\Console\Style\SymfonyStyle
   */
  protected $io;

  public function exec($cwd, $command, &$lines = NULL, &$result = NULL) {
    if ($cwd) {
      $this->io->writeln("<comment>\$</comment> $command <comment>[[in $cwd]]</comment>", OutputInterface::VERBOSITY_VERBOSE);
      $oldCwd = getcwd();
      chdir($cwd);
      exec($command, $lines, $result);
      chdir($oldCwd);
    }
    else {
      $this->io->writeln("<comment>\$</comment> $command", OutputInterface::VERBOSITY_VERBOSE);
      exec($command, $lines, $result);
    }
  }

  public function passthruOk($command, &$result = NULL) {
    $this->io->writeln("<comment>\$</comment> $command", OutputInterface::VERBOSITY_VERBOSE);
    passthru($command, $result);
    if ($result !== 0) {
      throw new \Exception("Command failed: \"$command\"");
    }
  }

});

$c['gsutil'] = $c->autowiredObject(new class() {

  /**
   * @var \Symfony\Component\Console\Input\InputInterface
   */
  protected $input;

  /**
   * @var \Symfony\Component\Console\Style\SymfonyStyle
   */
  protected $io;

  protected $runner;

  public function list($arg) {
    $command = "gsutil ls " . escapeshellarg($arg);
    $this->runner->exec(NULL, $command, $lines, $result);
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

  public function copy($src, $dest) {
    $this->io->writeln("Copy <comment>$src</comment> to <comment>$dest</comment>");
    $command = sprintf("gsutil cp %s %s", escapeshellarg($src),
      escapeshellarg($dest));
    $this->runner->exec(NULL, $command, $lines, $result);
    if ($result !== 0) {
      throw new \Exception("Command failed: \"$command\": " . implode("\n",
          $lines));
    }
  }

});

/**
 * Call a git subcommand.
 *
 * @param string $path
 *   Ex: /var/www/sites/all/modules/civicrm.
 * @param string $command
 *   Ex: git fetch origin
 * @throws \Exception
 */
$c['git()'] = function ($path, $command, $runner) {
  $result = NULL;
  $runner->exec($path, $command, $lines, $result);

  if ($result !== 0) {
    throw new \Exception("Command failed in \"$path\": \"$command\": " .
      implode("\n", $lines));
  }
};

/**
 * Send tags to a remote
 *
 * @param array $newTags
 * @param string $gitRemote
 * @param \Symfony\Component\Console\Input\InputInterface $input
 * @param \Symfony\Component\Console\Style\SymfonyStyle $io
 */
$c['gitTag()'] = function (array $newTags, string $gitRemote, $input, $io, $git) {
  $force = $input->getOption('force') ? '-f' : '';

  // Do all the local ops first. Progress toward more risky/enduring.

  foreach ($newTags as $todo) {
    $git($todo['path'], sprintf("git fetch %s", escapeshellarg($gitRemote)));
  }

  foreach ($newTags as $todo) {
    $git($todo['path'],
      sprintf("git tag %s %s %s", $force,
        escapeshellarg($todo['tag']), escapeshellarg($todo['commit'])));
  }

  if (!$input->getOption('dry-run')) {
    foreach ($newTags as $todo) {
      $git($todo['path'], sprintf("git push %s %s %s", escapeshellarg($gitRemote), $force, escapeshellarg($todo['tag'])));
    }
  }
};

/**
 * Create a client for communicating with Gitlab API.
 *
 * @param string $url
 *   Base URL for Gitlab project (https:///DOMAIN/OWNER/REPO).
 * @return \GuzzleHttp\Client
 */
$c['gitlabClient()'] = function($url, Credentials $cred, HandlerStack $guzzleHandler) {
  assertThat(preg_match(';https?://[^/]+/[^/]+/[^/]+;', $url), "Project URL should match pattern: https:///DOMAIN/OWNER/REPO");
  list ($scheme, , $host, $owner, $repo) = explode('/', $url);

  static $credCache = [];
  $credCache[$host] = $credCache[$host] ?? $cred->get('LAB_TOKEN', $host);

  $client = new \GuzzleHttp\Client([
    'base_uri' => "{$scheme}//{$host}/api/v4/projects/{$owner}%2F{$repo}/",
    'headers' => ['PRIVATE-TOKEN' => $credCache[$host]],
    'handler' => $guzzleHandler,
  ]);
  return $client;
};

/**
 * Ensure that the given Gitlab release exists.
 *
 * @param \GuzzleHttp\Client
 *   Client for talking with a Gitlab project.
 * @param string $verNum
 *   The version that should exist.
 */
$c['gitlabRelease()'] = function($client, $verNum, SymfonyStyle $io) {
  try {
    $client->get('releases/' . urlencode($verNum) . '/');
  }
  catch (\Exception $e) {
    $client->post('releases', [
      'form_params' => [
        'name' => $verNum,
        'tag_name' => $verNum,
        'description' => $verNum,
      ],
    ]);
  }
};

/**
 * Upload a list of files to Gitlab. Attach them to a specific release.
 *
 * @param string $gitlabUrl
 *   Base URL for Gitlab (https://DOMAIN)
 * @param string $project
 *   Name of Gitlab project (OWNER/REPO)
 * @param string $verNum
 * @param string[] $assets
 *   List of local files to upload. The remote file will have a matching name.
 */
$c['gitlabUpload()'] = function (string $gitlabUrl, string $project, string $verNum, array $assets, SymfonyStyle $io, $gitlabClient, $input, $gitlabRelease) {
  $verbose = function($data) use ($io) {
    return $io->isVerbose() ? toJSON($data) : '';
  };
  $projectUrl = joinUrl($gitlabUrl, $project);

  $client = $gitlabClient($projectUrl);
  assertThat(preg_match('/^\d[0-9a-z\.\-\+]*$/', $verNum));
  $io->writeln(sprintf("<info>Upload to project <comment>%s</comment> for version <comment>%s</comment> with files:\n<comment>  * %s</comment></info>", $projectUrl, $verNum, implode("\n  * ", $assets)));

  $gitlabRelease($client, $verNum);

  try {
    $existingAssets = fromJSON($client->get('releases/' . urlencode($verNum) . '/assets/links'));
    $existingAssets = index(['name'], $existingAssets);
  }
  catch (\Exception $e) {
    $existingAssets = [];
  }

  foreach ($assets as $asset) {
    assertThat(file_exists($asset), "File $asset does not exist");
    if ($input->getOption('dry-run')) {
      $io->note("(DRY-RUN) Skipped upload of $asset");
      continue;
    }
    $upload = fromJSON($client->post('uploads', [
      'multipart' => [
        ['name' => 'file', 'contents' => fopen($asset, 'r')],
      ],
    ]));
    $io->writeln("<info>Created new upload</info> " . $verbose($upload));

    if (isset($existingAssets[basename($asset)])) {
      $delete = fromJSON($client->delete('releases/' . urlencode($verNum) . '/assets/links/' . $existingAssets[basename($asset)]['id']));
      $io->writeln("<info>Deleted old upload</info> " . $verbose($delete));
      // Should we also delete the previous upload? Is that possible?
    }

    $release = fromJSON($client->post('releases/' . urlencode($verNum) . '/assets/links', [
      'form_params' => [
        'name' => basename($asset),
        'url' => joinUrl($gitlabUrl, $upload['full_path']),
      ],
    ]));
    $io->writeln("<info>Updated release</info> " . $verbose($release));
  }
};

###############################################################################
## Tasks

/**
 * Download the prepared tarballs.
 *
 * @param array $versionSpec
 * @param \Symfony\Component\Console\Input\InputInterface $input
 * @param \Symfony\Component\Console\Style\SymfonyStyle $io
 */
$c['task_get()'] = function (array $versionSpec, $input, $io, $gsutil) {
  $io->section('Get the RC or nightly build');
  $filePat = $versionSpec['prefix'] . '/civicrm-*' . $versionSpec['version'] . '*' . (empty($versionSpec['timestamp']) ? '' : ($versionSpec['timestamp'] . '*'));
  $fileUrls = $gsutil->list($filePat);
  foreach ($fileUrls as $fileUrl) {
    if (empty($versionSpec['timestamp'])) {
      $filePath = $versionSpec['stagingDir'] . '/' . basename($fileUrl);
    }
    else {
      $filePath = $versionSpec['stagingDir'] . '/' . str_replace('-' . $versionSpec['timestamp'], '', basename($fileUrl));
    }
    if (file_exists($filePath)) {
      if (!$input->getOption('force')) {
        $io->writeln("Skipped item: <comment>$filePath</comment> already exists");
        continue;
      }
      $io->writeln("Overwrite <comment>$filePath</comment>");
    }
    $gsutil->copy($fileUrl, $filePath);
  }
};

/**
 * Generate checksum and GPG signature
 * @param array $versionSpec
 * @param \Symfony\Component\Console\Input\InputInterface $input
 * @param \Symfony\Component\Console\Style\SymfonyStyle $io
 */
$c['task_sign()'] = function (array $versionSpec, $input, $io, $runner, \Crypt_GPG $gpg) {
  $io->section('Generate checksum and GPG signature');

  $md5File = 'civicrm-' . $versionSpec['version'] . '.MD5SUMS';
  $sha256File = 'civicrm-' . $versionSpec['version'] . '.SHA256SUMS';

  $runner->exec($versionSpec['stagingDir'],
    sprintf("md5sum *.tar.gz *.zip *.json > %s", escapeshellarg($md5File)));
  $runner->exec($versionSpec['stagingDir'],
    sprintf("sha256sum *.tar.gz *.zip *.json > %s", escapeshellarg($sha256File)));

  if (!$input->getOption('dry-run')) {
    $base = $versionSpec['stagingDir'];
    foreach (["$base/$md5File", "$base/$sha256File"] as $file) {
      $gpg->signFile("$file", "$file.asc", \Crypt_GPG::SIGN_MODE_DETACHED);
      assertThat(!empty($gpg->verifyFile($file, file_get_contents("$file.asc"))), "$file should have valid signature");
    }
  }
};

/**
 * Generate and push git tags.
 *
 * @param array $versionSpec
 * @param \Symfony\Component\Console\Input\InputInterface $input
 * @param \Symfony\Component\Console\Style\SymfonyStyle $io
 */
$c['task_tag()'] = function (array $versionSpec, $input, $io, $gitTag) {
  $io->section('Generate and push git tags');
  $jsonFile = sprintf("%s/civicrm-%s.json", $versionSpec['stagingDir'], $versionSpec['version']);
  $versionJson = json_decode(file_get_contents($jsonFile), 1);
  $newTags = task_tag_plan($versionSpec, $versionJson);
  $gitRemote = $input->getOption('git-remote');
  $gitTag($newTags, $gitRemote);
};

/**
 * Generate and push git tags.
 *
 * @param array $versionSpec
 * @param \Symfony\Component\Console\Input\InputInterface $input
 * @param \Symfony\Component\Console\Style\SymfonyStyle $io
 */
$c['task_esr_tag()'] = function (array $versionSpec, $input, $io, $gitTag) {
  $io->section('Generate and push git tags');
  $jsonFile = sprintf("%s/civicrm-%s.json", $versionSpec['stagingDir'], $versionSpec['version']);
  $versionJson = json_decode(file_get_contents($jsonFile), 1);
  $newTags = task_tag_plan($versionSpec, $versionJson, '+esr');
  $gitRemote = 'esr';
  // $gitRemote = $input->getOption('git-remote');
  $gitTag($newTags, $gitRemote);
};

/**
 * Send build to primary download service.
 *
 * @param array $versionSpec
 * @param \Symfony\Component\Console\Input\InputInterface $input
 * @param \Symfony\Component\Console\Style\SymfonyStyle $io
 */
$c['task_publish()'] = function (array $versionSpec, $input, $io, $runner, Credentials $cred) {
  $io->section('Publish tarballs to primary download service');

  // Get missing info before doing anything
  $io->writeln('This will be uploaded to sf.net. To mark it as the default download on sf.net, one needs an api_key. (To skip, leave blank.)');
  $sfApiKey = $cred->get('FORGE_TOKEN');
  if (empty($sfApiKey)) {
    $io->warning('No api_key specified. Will not update default download on sourceforge.net.');
  }

  // Execute, such as it is
  $io->writeln('Send build to primary download service');
  $dry = $input->getOption('dry-run') ? '-n' : '';
  $runner->passthruOk(sprintf("gsutil rsync $dry %s/ %s/",
    escapeshellarg($versionSpec['stagingDir']),
    escapeshellarg('gs://civicrm/civicrm-stable/' . $versionSpec['version'])
  ));
  $runner->passthruOk(sprintf("rsync -va $dry %s/ %s/",
    escapeshellarg($versionSpec['stagingDir']),
    escapeshellarg('civicrm@frs.sourceforge.net:/home/frs/project/civicrm/civicrm-stable/' . $versionSpec['version'])
  ));

  if ($sfApiKey) {
    // See also: https://sourceforge.net/p/forge/documentation/Using%20the%20Release%20API/
    $project = 'civicrm';
    $defaultDownloadFile = sprintf('civicrm-stable/%s/civicrm-%s-drupal.tar.gz', $versionSpec['version'], $versionSpec['version']);
    $defaultDownloadUrl = "https://sourceforge.net/projects/{$project}/files/{$defaultDownloadFile}";
    $io->writeln(sprintf('Mark "%s" as default download', $defaultDownloadFile));
    $curlCmd = sprintf('%s --fail -H %s -X PUT -d %s -d %s %s',
      ($input->getOption('dry-run') ? 'echo curl' : 'curl'),
      escapeshellarg("Accept: application/json"),
      escapeshellarg("default=windows&default=mac&default=linux&default=bsd&default=solaris&default=others"),
      escapeshellarg("api_key=$sfApiKey"),
      escapeshellarg($defaultDownloadUrl)
    );
    $runner->passthruOk($curlCmd);
  }
};

/**
 * Send build to ESR download service.
 *
 * @param array $versionSpec
 * @param \Symfony\Component\Console\Input\InputInterface $input
 * @param \Symfony\Component\Console\Style\SymfonyStyle $io
 */
$c['task_esr_publish()'] = function (array $versionSpec, $input, $io, $runner, $gitlabUpload, $gitlabClient) {
  $gitlabUrl = 'https://lab.civicrm.org';
  $files = (array) glob($versionSpec['stagingDir'] . '/civicrm*');
  if (empty($files)) {
    throw new \Exception("Failed to find assets in " . $versionSpec['stagingDir']);
  }
  $esrVer = $versionSpec['version'] . '+esr';

  $io->section("Publish ESR tarballs to Gitlab ($gitlabUrl/esr/core)");
  $gitlabUpload($gitlabUrl, "/esr/core", $esrVer, $files);

  $io->section('Publish ESR tarballs to Google Cloud');
  $dry = $input->getOption('dry-run') ? '-n' : '';
  $runner->passthruOk(sprintf("gsutil -m rsync $dry %s/ %s/",
    escapeshellarg($versionSpec['stagingDir']),
    escapeshellarg('gs://civicrm-private/civicrm-esr/' . $versionSpec['version'])
  ));

  $composerProjects = ['esr/core' => 558, 'esr/packages' => 1092, 'esr/drupal-8' => 1093];
  foreach ($composerProjects as $prjName => $prjId) {
    $io->section("Update ESR composer feed ($gitlabUrl/$prjName aka #{$prjId})");
    // For some reason, the `packages/composer` API doesn't seem to work with the symbolic project name...
    // $gitlabClient("$gitlabUrl/$prjName")->post('packages/composer', [
    $gitlabClient("$gitlabUrl/esr/core")->post("$gitlabUrl/api/v4/projects/$prjId/packages/composer", [
      'form_params' => ['tag' => $esrVer],
    ]);
  }
};

/**
 * Delete any temp files.
 *
 * @param array $versionSpec
 * @param \Symfony\Component\Console\Input\InputInterface $input
 * @param \Symfony\Component\Console\Style\SymfonyStyle $io
 */
$c['task_clean()'] = function ($versionSpec, $input, $io, $runner) {
  $io->section('Cleanup temp files');
  if (file_exists($versionSpec['stagingDir'])) {
    $parentDir = dirname($versionSpec['stagingDir']);
    $childDir = basename($versionSpec['stagingDir']);
    $dry = $input->getOption('dry-run') ? 'echo ' : '';
    $runner->exec($parentDir, sprintf("%s rm -rf %s", $dry, escapeshellarg($childDir)));
  }
};

/**
 * @param array $versionSpec
 * @param \Symfony\Component\Console\Style\SymfonyStyle $io
 */
$c['task_debug()'] = function(array $versionSpec, $io) use ($c) {
  $io->section('Debug: Version spec');
  $vsRows = [];
  foreach ($versionSpec as $k => $v) {
    $vsRows[] = [$k, $v];
  }
  $io->table(['key', 'value'], $vsRows);

  $io->section('Debug: Services');
  $io->table(['service id'], array_map(
    function($key) {
      return [$key];
    },
    $c->keys()
  ));
};

###############################################################################
## Main
// FIXME: Help should show an example, echo "example: releaser gs://civicrm-build/4.7.19-rc/civicrm-4.7.19-201705020430.json --get --sign\n";
// FIXME: Help should show a task list
$c['app']->main('[-f|--force] [-N|--dry-run] [--git-remote=] json-url tasks*', function($tasks, InputInterface $input, SymfonyStyle $io) use ($c) {
  $defaults = ['git-remote' => 'origin'];
  foreach ($defaults as $option => $value) {
    if (!$input->getOption($option)) {
      $input->setOption($option, $value);
    }
  }

  $tasks = array_map(function ($t) {
    return str_replace('-', '_', $t);
  }, $tasks);

  foreach ($tasks as $task) {
    assertThat($c->has('task_' . $task), "Unrecognized task: $task");
  }

  if (!empty($tasks)) {
    if ($vars = $io->askHidden('(Optional) Paste a batch list of secrets (KEY1=VALUE1 KEY2=VALUE2...)')) {
      assertThat(!preg_match(';[\'\\"];', $vars), "Sorry, not clever enough to handle meta-characters.");
      foreach (explode(' ', $vars) as $keyValue) {
        [$key, $value] = explode('=', $keyValue, 2);
        putenv($keyValue);
        $_ENV[$key] = $_SERVER[$key] = $value;
      }
    }
  }

  foreach ($tasks as $task) {
    $c['task_' . $task]();
  }
});

###############################################################################

/**
 * Build a list of tags that should exist.
 *
 * @param array $versionSpec
 * @param array $versionJson
 * @param string $tagSuffix
 *   Ex: '+esr'
 * @return array
 *   Each item has:
 *     - path: string, the file path to the local repo
 *     - tag: string, the name of a new git tag
 *     - commit: string, git sha1 hash
 * @throws \Exception
 */
function task_tag_plan($versionSpec, $versionJson, $tagSuffix = '') {
  $repoPaths = array(
    "civicrm-drupal" => $versionSpec['gitDir'] . "/drupal",
    "civicrm-drupal-8" => $versionSpec['gitDir'] . "/drupal-8",
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
      $tagName = $tagPrefix . '-' . $versionSpec['version'] . $tagSuffix;
    }
    else {
      $repoName = $repoDesc;
      $tagName = $versionSpec['version'] . $tagSuffix;
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
