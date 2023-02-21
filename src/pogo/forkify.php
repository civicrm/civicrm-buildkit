#!/usr/bin/env pogo
<?php

## The "forkify" command manages a series of related forks/branches across a handful of repos.
## Generally, it is designed to work with the canonical "dist" layout. It can be useful for tasks like:
##
##  - Adding the remotes for "security", "esr", or your personal forks.
##  - Fetching the remotes for "security", "esr", or your personal forks.
##  - Initializing the set of branches for "X.Y-security" and "X.Y-esr".
##
## TIP: The `-N` or `--dry-run` is quite helpful for inspecting operation.

###############################################################################
#### TOC
##
## - Documentation (Code Conventions)
## - Imports
## - Commands
## - Services (Helpers/Utilities)

###############################################################################
#### Documentation (Code Conventions)
##
## `forkify` is built on the clippy/silly framework, which allows you to define multiple commands using a pithy,
## type-checked notation. Suppose you want to support this command-line call:
##
##   forkify do:stuff -f hello-world.txt
##
## You would declare the `do:stuff` command like so:
##
##   $c['app']->command("do:stuff [-f|--force] filename", function (bool $force, string $filename, SymfonyStyle $io) {
##
## This example declaration has two parts:
##
##   - CLI SIGNATURE: The command is named `do:stuff` and accepts a CLI option `--force` (aliased as `-f`)
##     along with a CLI argument `filename`.
##   - PHP CALLBACK: The callback receives the CLI option (`bool $force`), CLI argument (`string $filename`), and
##     a container-based service (`SymfonyStyle $io`). This is a dependency-injection mechanism -- you may inject
##     any parameters as you need, as long as they correspond to options/arguments/services.
##
## Some commonly injected services are:
##
##   - `SymfonyStyle $io`: High-level helper for interacting with a user (input+output)
##   - `InputInterface $input`: Basic CLI input data
##   - `OutputInterface $output`: Basic CLI output methods
##   - `Repos $repos`: Methods for finding/visiting the various git repos
##
## Additionally, you may add more container-based services, e.g.
##
##   $c['myService'] = function(injectedData...) { return 'service-object'; }
##   $c['myService'] = $c->autowiredObject(new MyServiceClass());
##   $c['myMethod()'] = function(params..., injectedData...) { return 'my-result';}
##
## See also:
##
## * https://github.com/clippy-php/std
## * https://github.com/clippy-php/container
## * https://github.com/mnapoli/silly/

###############################################################################
#### Imports

#!ttl 10 years
#!require clippy/std: ~0.4.2
#!require clippy/container: '~1.2'

namespace Clippy;

use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Question\ChoiceQuestion;
use Symfony\Component\Console\Style\SymfonyStyle;

$c = clippy()->register(plugins());

###############################################################################
#### Commands
$globalOptions = '[-N|--dry-run] [-A|--expect-all] [-S|--step] [--root=]';

$c['app']->command("remote:add $globalOptions remote url-prefix", function ($remote, $urlPrefix, SymfonyStyle $io, Repos $repos, Taskr $taskr) {
  $remoteUrls = $repos->remoteUrls($remote, $urlPrefix);
  $repos->walk($remoteUrls, function ($name, $path, $remote, $url) use ($io, $taskr) {
    $io->writeln("<comment>$path</comment>: Add remote <comment>$remote</comment> (<comment>$url</comment>)");
    $taskr->passthru('git remote add {{0|s}} {{1|s}}', [$remote, $url]);
  });
})->setAliases(['add-remotes'])
  ->setDescription('Add parallel remotes across Civi-related repos');

$c['app']->command("remote:set-url $globalOptions remote url-prefix", function ($remote, $urlPrefix, SymfonyStyle $io, Repos $repos, Taskr $taskr) {
  $remoteUrls = $repos->remoteUrls($remote, $urlPrefix);
  $repos->walk($remoteUrls, function ($name, $path, $remote, $url) use ($io, $taskr) {
    $io->writeln("<comment>$path</comment>: Update remote <comment>$remote</comment> (<comment>$url</comment>)");
    $taskr->passthru('git remote set-url {{0|s}} {{1|s}}', [$remote, $url]);
  });
})->setAliases(['set-remotes'])
  ->setDescription('Update parallel remotes across Civi-related repos');;

$c['app']->command("remote:fetch $globalOptions [remotes]*", function ($remotes, SymfonyStyle $io, Repos $repos, Taskr $taskr) {
  if (empty($remotes)) {
    $remotes[] = 'origin';
  }
  foreach ($remotes as $remote) {
    $remoteUrls = $repos->remoteUrls($remote, '!!not-applicable');
    $repos->walk($remoteUrls, function ($name, $path, $remote) use ($io, $taskr) {
      $io->writeln("[<comment>$path</comment>]: Fetch remote <comment>$remote</comment>");
      $taskr->passthru('git fetch {{0|s}}', [$remote]);
    });
  }
})->setAliases(['fetch']);

$c['app']->command("branch:create $globalOptions target source", function ($target, $source, SymfonyStyle $io, Repos $repos, Taskr $taskr) {
  $branchPairs = $repos->branchPairs($target, $source);
  $repos->walk($branchPairs, function ($name, $path, $tgtRemote, $tgtBranch, $srcRemote, $srcBranch) use ($io, $taskr) {
    $tgtName = ($tgtRemote ? "$tgtRemote/$tgtBranch" : "$tgtBranch");
    $srcName = ($srcRemote ? "$srcRemote/$srcBranch" : "$srcBranch");
    $io->writeln("<comment>$path</comment>: Create branch <comment>$tgtName</comment> from <comment>$srcName</comment>");
    $taskr->passthru('git branch {{0|s}} {{1|s}}', [$tgtBranch, "$srcRemote/$srcBranch"]);
    if ($tgtRemote) {
      $taskr->passthru('git config branch.{{0|s}}.remote {{1|s}}', [$tgtBranch, $tgtRemote]);
      $taskr->passthru('git config branch.{{0|s}}.merge refs/heads/{{1|s}}', [$tgtBranch, $tgtBranch]);
    }
  });
})->setAliases(['branch'])
  ->setDescription('Create parallel branches across Civi-related repos');

$c['app']->command("branch:update $globalOptions [--merge] [--ff-only] [--rebase] target source", function ($target, $source, SymfonyStyle $io, Repos $repos, Taskr $taskr, $pickMergeOpts) {
  $branchPairs = $repos->branchPairs($target, $source);
  $mergeOpts = $pickMergeOpts();

  $repos->walk($branchPairs, function ($name, $path, $tgtRemote, $tgtBranch, $srcRemote, $srcBranch) use ($io, $taskr, $mergeOpts) {
    $io->writeln("<comment>$path</comment>: Update branch <comment>$tgtRemote/$tgtBranch</comment> from <comment>$srcRemote/$srcBranch</comment>");
    assertThat($tgtRemote && $tgtBranch && $srcRemote && $srcBranch, "Target and source must be fully specified (remote/branch).");
    $params = [
      'MERGE_OPTS' => $mergeOpts,
      'TGT_BR' => $tgtBranch,
      'TGT_RM' => $tgtRemote,
      'SRC_BR' => $srcBranch,
      'SRC_RM' => $srcRemote,
    ];
    $taskr->passthru('git checkout {{TGT_BR|s}} && git pull {{MERGE_OPTS}} {{SRC_RM|s}} {{SRC_BR|s}} && git push {{TGT_RM}} {{TGT_BR}}', $params);
  });
})->setAliases(['update'])
  ->setDescription('Pull and push updates for parallel branches across Civi-related repos');

$c['app']->command("branch:pull $globalOptions [--merge] [--ff-only] [--rebase] target source", function ($target, $source, SymfonyStyle $io, Repos $repos, Taskr $taskr, $pickMergeOpts) {
  $branchPairs = $repos->branchPairs($target, $source);
  $mergeOpts = $pickMergeOpts();

  $repos->walk($branchPairs, function ($name, $path, $tgtRemote, $tgtBranch, $srcRemote, $srcBranch) use ($io, $taskr, $mergeOpts) {
    $io->writeln("<comment>$path</comment>: Update branch <comment>$tgtRemote/$tgtBranch</comment> from <comment>$srcRemote/$srcBranch</comment>");
    assertThat(!$tgtRemote && $tgtBranch, "Target must only specify branch name (no remote)");
    assertThat($srcRemote && $srcBranch, "Source must be fully specified (remote/branch).");
    $params = [
      'MERGE_OPTS' => $mergeOpts,
      'TGT_BR' => $tgtBranch,
      'SRC_BR' => $srcBranch,
      'SRC_RM' => $srcRemote,
    ];
    $taskr->passthru('git checkout {{TGT_BR|s}} && git pull {{MERGE_OPTS}} {{SRC_RM|s}} {{SRC_BR|s}}', $params);
  });
})->setAliases(['pull'])
  ->setDescription('Pull updates into parallel branches across Civi-related repos');

$c['app']->command("branch:push $globalOptions [-f|--force] [-u|--set-upstream] remote branch", function ($remote, $branch, $force, $setUpstream, SymfonyStyle $io, Repos $repos, Taskr $taskr) {
  $branches = $repos->branches("$remote/$branch");
  $repos->walk($branches, function ($name, $path, $remote, $branch) use ($io, $taskr, $force, $setUpstream) {
    $io->writeln("<comment>$path</comment>: Push branch <comment>$branch</comment> to <comment>$remote</comment>");
    $params = [
      'SETUP' => $setUpstream ? '-u' : '',
      'FORCE' => $force ? '-f' : '',
      'REMOTE' => $remote,
      'BRANCH' => $branch,
    ];
    $taskr->passthru('git push {{FORCE}} {{SETUP}} {{REMOTE|s}} {{BRANCH|s}}', $params);
  });
})->setAliases(['push']);

$c['app']->command("branch:checkout $globalOptions branch [--core=] [--packages=] [--backdrop=] [--drupal=] [--joomla=] [--wordpress=]", function ($branch, SymfonyStyle $io, Repos $repos, Taskr $taskr, InputInterface $input) {
  $branches = $repos->branches($branch);
  $repos->walk($branches, function ($name, $path, $remote, $branch) use ($io, $input, $taskr) {
    if ($input->hasOption($name) && $input->getOption($name)) {
      // Caller requested a different branch for this repo (e.g. "givi checkout master --core=my-wip-pr")
      $branch = $input->getOption($name);
    }

    $io->writeln("<comment>$path</comment>: Checkout branch <comment>$branch</comment>");
    $taskr->passthru('git checkout {{0|s}}', [
      $remote ? "$remote/$branch" : $branch,
    ]);
  });
})->setAliases(['checkout'])
  ->setDescription('Checkout parallel branches across Civi-related repos');

$c['app']->command("branch:delete $globalOptions [-f|--force] branch", function ($branch, $force, SymfonyStyle $io, Repos $repos, Taskr $taskr) {
  $branches = $repos->branches($branch);
  $repos->walk($branches, function ($name, $path, $remote, $branch) use ($io, $taskr, $force) {
    $io->writeln("<comment>$path</comment>: Delete branch <comment>$branch</comment>");
    $mode = $force ? '-D' : '-d';
    $taskr->passthru('git show-ref --quiet refs/heads/{{1|s}} && git branch {{0|s}} {{1|s}} || echo {{2|s}}',
      [$mode, $branch, '(Ignore missing branch)']);
  });
})->setDescription('Delete parallel branches across Civi-related repos');

$c['app']->command("status $globalOptions", function (SymfonyStyle $io, Repos $repos, Taskr $taskr) {
  $remoteUrls = $repos->remoteUrls('origin', '!!not-applicable');
  $repos->walk($remoteUrls, function ($name, $path, $remote) use ($io, $taskr) {
    $io->writeln("[<comment>$path</comment>]: Check status");
    $taskr->passthru('git status', []);
  });
})->setDescription("Display local status across Civi-related repos");

$c['app']->command('wf:unimplemented', function (SymfonyStyle $io) {
  $io->error([
    "The \"givi\" command included some workflow helpers (\"givi begin\", \"givi resume\", \"givi review\").",
    "These subcommands were dropped during a bigger code reorganiztion. If you would like these subcommands to be restored, please file an issue or PR.",
    // Well, specifically, I used them for a few months back in `$ancientYear` -- and then moved on to other commands.
    // We never really advertised these, so I doubt anyone else used them. Won't bother porting
    // them unless someone actually uses them.
  ]);
  return 1;
})->setAliases(['begin', 'resume', 'review'])->setDescription("(Unimplemented)");

$c['app']->command("wf:rc $globalOptions", function (callable $runSubcommand, Repos $repos, SymfonyStyle $io, Taskr $taskr) {
  chdir($repos->getPath('.'));

  $io->section("\nCheckout latest \"master\" branches");
  // $runSubcommand("checkout -A master");
  $runSubcommand("pull -A --ff-only master origin/master");

  $io->section("\nConfirm versions");
  $xmlObj = \simplexml_load_string(file_get_contents("xml/version.xml"));
  $oldVer = (string) $xmlObj->version_no;
  [$major, $minor, $patch] = explode('.', $oldVer);

  $rcMajorMinor = $major . '.' . $minor;
  $devMajorMinor = $major . '.' . (1 + $minor);

  $io->text("Branch <comment>master</comment> currently has version <comment>$oldVer</comment>.");
  $io->newLine();
  $io->text("The update will:");
  $io->newLine();
  $io->listing([
    "Raise the version to <comment>$rcMajorMinor.beta1</comment>.",
    "Create branch <comment>$rcMajorMinor</comment>.",
    "Raise the version to <comment>$devMajorMinor.alpha1</comment>.",
  ]);

  if (!$io->confirm("Proceed with updates?")) {
    throw new \RuntimeException("User aborted");
  }

  $io->section("\nRaise version to \"$rcMajorMinor.beta1\"");
  $taskr->passthru('./tools/bin/scripts/set-version.php {{0|s}} --commit', ["{$rcMajorMinor}.beta1"]);
  $taskr->passthru('git push origin master');

  $io->section("\nMake branch \"$rcMajorMinor\"");
  $runSubcommand("branch $rcMajorMinor origin/master");
  $runSubcommand("push -A -u origin $rcMajorMinor");

  $io->section("\nRaise version to \"$devMajorMinor.alpha1\"");
  $runSubcommand("checkout -A master");
  $taskr->passthru('./tools/bin/scripts/set-version.php {{0|s}} --commit', ["{$devMajorMinor}.alpha1"]);
  $runSubcommand("push -A origin master");
})->setDescription('Create new RC and bump up version numbers.');

###############################################################################
#### Services (Helpers/Utilities)

/**
 * Get information about (and send tasks to) the various Civi-related repos.
 */
class Repos {

  /**
   * @var \Symfony\Component\Console\Style\SymfonyStyle
   */
  protected $io;

  /**
   * @var \Symfony\Component\Console\Input\InputInterface
   */
  protected $input;

  public function getPath(string $subdir) {
    if ($this->input->hasOption('root') && $this->input->getOption('root')) {
      $base = rtrim($this->input->getOption('root'), '/' . DIRECTORY_SEPARATOR);
    }
    else {
      $base = '.';
    }
    return ($subdir === '.')
      ? $base
      : ($base . DIRECTORY_SEPARATOR . $subdir);
  }

  protected function pickWordPress(): string {
    // In standard 'dist' layout, civicrm-wordpress is a child dir. But in live WP install, it's the parent.
    $parent = $this->getPath('..');
    $child = $this->getPath('WordPress');
    if (file_exists("$parent/wp-cli/civicrm.php") && !file_exists($child)) {
      return $parent;
    }
    else {
      return $child;
    }
  }

  /**
   * @param string $remote
   * @param string $urlPrefix
   * @return array
   *   List of repos and their corresponding remotes/URLs. Each has properties: name, path, remote, url
   */
  public function remoteUrls(string $remote, string $urlPrefix): array {
    $suffix = '.git';
    return rekeyItems(['name', 'path', 'remote', 'url'], [
      ['core', $this->getPath('.'), $remote, "{$urlPrefix}core{$suffix}"],
      ['backdrop', $this->getPath('backdrop'), $remote, "{$urlPrefix}backdrop{$suffix}"],
      ['drupal', $this->getPath('drupal'), $remote, "{$urlPrefix}drupal{$suffix}"],
      ['drupal-8', $this->getPath('drupal-8'), $remote, "{$urlPrefix}drupal-8{$suffix}"],
      ['joomla', $this->getPath('joomla'), $remote, "{$urlPrefix}joomla{$suffix}"],
      ['packages', $this->getPath('packages'), $remote, "{$urlPrefix}packages{$suffix}"],
      ['wordpress', $this->pickWordPress(), $remote, "{$urlPrefix}wordpress{$suffix}"],
    ]);
  }

  /**
   * @param string $branchExpr
   *   Ex: '5.51' or '5.51-security' or 'security/5.51-security'
   * @return array
   *   List of repos and their corresponding branches. Each has properties: name, path, branch, remote
   */
  public function branches(string $branchExpr): array {
    [$remote, $branch] = $this->parseRemoteBranch($branchExpr);
    return rekeyItems(['name', 'path', 'remote', 'branch'], [
      ['core', $this->getPath('.'), $remote, $branch],
      ['backdrop@1.x', $this->getPath('backdrop'), $remote, "1.x-$branch"],
      ['drupal@7.x', $this->getPath('drupal'), $remote, "7.x-$branch"],
      ['drupal-8', $this->getPath('drupal-8'), $remote, $branch],
      ['joomla', $this->getPath('joomla'), $remote, $branch],
      ['packages', $this->getPath('packages'), $remote, $branch],
      ['wordpress', $this->pickWordPress(), $remote, $branch],
    ]);
  }

  /**
   * @param string $tgt
   *   Ex: 'security/5.51-security'
   * @param string $src
   *   Ex: 'origin/5.51'
   * @return array
   *   List of repos and their corresponding branch-pairs. Each has properties: name, tgtRemote, tgtBranch, srcRemote, srcBranch
   */
  public function branchPairs(string $tgt, string $src): array {
    [$tgtRemote, $tgtBranch] = $this->parseRemoteBranch($tgt);
    [$srcRemote, $srcBranch] = $this->parseRemoteBranch($src);

    return rekeyItems(['name', 'path', 'tgtRemote', 'tgtBranch', 'srcRemote', 'srcBranch'], [
      ['core', $this->getPath('.'), $tgtRemote, $tgtBranch, $srcRemote, $srcBranch],
      ['backdrop@1.x', $this->getPath('backdrop'), $tgtRemote, "1.x-$tgtBranch", $srcRemote, "1.x-$srcBranch"],
      ['drupal@7.x', $this->getPath('drupal'), $tgtRemote, "7.x-$tgtBranch", $srcRemote, "7.x-$srcBranch"],
      ['drupal-8', $this->getPath('drupal-8'), $tgtRemote, $tgtBranch, $srcRemote, $srcBranch],
      ['joomla', $this->getPath('joomla'), $tgtRemote, $tgtBranch, $srcRemote, $srcBranch],
      ['packages', $this->getPath('packages'), $tgtRemote, $tgtBranch, $srcRemote, $srcBranch],
      ['wordpress', $this->pickWordPress(), $tgtRemote, $tgtBranch, $srcRemote, $srcBranch],
    ]);
  }

  /**
   * @param array $tasks
   *   A list of tasks.
   *   Each task should have the same internal structure.
   * @param callable $f
   *   A function to call for each task. The tasks will be exploded, as in:
   *   $f(...array_values($task)).
   * @return array
   *   The result of each call to $f.
   * @throws \Exception
   */
  public function walk(array $tasks, callable $f): array {
    if ($this->input->hasOption('expect-all') && $this->input->getOption('expect-all')) {
      $paths = \array_column($tasks, 'path');
      $foundPaths = \array_filter($paths, 'file_exists');
      $missingPaths = array_diff($paths, $foundPaths);
      if ($missingPaths) {
        throw new \Exception("Missing paths: " . implode(', ', $missingPaths));
      }
    }

    $cwd = pwd();
    $result = [];
    foreach ($tasks as $offset => $task) {
      if (!isset($task['path'])) {
        throw new \Exception("Item does not have a valid path: " . \json_encode($task));
      }
      if (!is_dir($task['path'])) {
        continue;
      }

      try {
        chdir($task['path']);
        $result[$offset] = $f(...array_values($task));
      } finally {
        chdir($cwd);
      }
    }

    return $result;
  }

  protected function parseRemoteBranch(string $expr): array {
    $parts = explode('/', $expr);
    switch (count($parts)) {
      case 1:
        return [NULL, $expr];

      case 2:
        return $parts;

      default:
        throw new \RuntimeException("Malformed remote branch name ($expr). Expected \"remote-name/branch-name\".");
    }
  }

}

$c['repos'] = $c->autowiredObject(new Repos());

$c['pickMergeOpts()'] = function(SymfonyStyle $io, InputInterface $input) {
  if (!$input->hasOption('ff-only') || !$input->hasOption('merge') || !$input->hasOption('rebase')) {
    throw new \Exception("Command is defined incorrectly. Must have options [--ff-only] [--merge] [--rebase]");
  }
  if ($input->getOption('ff-only')) {
    return '--ff-only';
  }
  elseif ($input->getOption('merge')) {
    return '';
  }
  elseif ($input->getOption('rebase')) {
    return '--rebase';
  }

  $choice = $io->askQuestion(new ChoiceQuestion('How should updates be applied?', [
    'f' => 'Fast forward',
    'm' => 'Merge',
    'r' => 'Rebase',
  ]));
  switch ($choice) {
    case 'f':
      return '--ff-only';

    case 'm':
      return '';

    case 'r':
      return '--rebase';
  }

  throw new \Exception("Must specify an update style: --merge or --rebase or --ff-only");
};

$c['runSubcommand()'] = function (string $cmd, array $params = [], ?Taskr $taskr = NULL, ?InputInterface $input = NULL) use ($c) {
  if ($input->getOption('expect-all')) {
    $cmdParts = explode(' ', $cmd, 2);
    array_splice($cmdParts, 1, 0, ["--expect-all"]);
    $cmd = implode(' ', $cmdParts);
  }
  $taskr->subcommand($cmd, $params);
};

/**
 * Get the present working directory (full path).
 *
 * @return string
 */
function pwd(): string {
  // exec(pwd) works better with symlinked source trees, but it's
  // probably not portable to Windows.
  if (strtoupper(substr(PHP_OS, 0, 3)) === 'WIN') {
    return getcwd();
  }
  else {
    exec('pwd', $output);
    return trim(implode("\n", $output));
  }
}

function rekeyItems(array $keyMap, array $items): array {
  $result = [];
  foreach ($items as $offset => $item) {
    $newItem = [];
    foreach ($keyMap as $oldKey => $newKey) {
      $newItem[$newKey] = $item[$oldKey];
    }
    $result[$offset] = $newItem;
  }
  return $result;
}

###############################################################################
## Go!

$c['app']->run();
