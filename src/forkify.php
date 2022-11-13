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

#!depdir './forkify-dep'
#!require clippy/std: ~0.3.5
#!require clippy/container: '~1.2'

###############################################################################
## Bootstrap
namespace Clippy;

use Symfony\Component\Console\Exception\InvalidArgumentException;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\Console\Question\ChoiceQuestion;
use Symfony\Component\Console\Style\SymfonyStyle;

$c = clippy()->register(plugins());

###############################################################################
## Commands

$globalOptions = '[-N|--dry-run] [-A|--expect-all] [-S|--step]';

$c['app']->command("remote:add $globalOptions remote url-prefix", function ($remote, $urlPrefix, SymfonyStyle $io, Repos $repos, callable $passthru) {
  $remoteUrls = $repos->remoteUrls($remote, $urlPrefix);
  $repos->walk($remoteUrls, function ($name, $path, $remote, $url) use ($io, $passthru) {
    $io->writeln("<comment>$path</comment>: Add remote <comment>$remote</comment> (<comment>$url</comment>)");
    $passthru('git remote add {{0|s}} {{1|s}}', [$remote, $url]);
  });
})->setAliases(['add-remotes'])
  ->setDescription('Add parallel remotes across Civi-related repos');

$c['app']->command("remote:set-url $globalOptions remote url-prefix", function ($remote, $urlPrefix, SymfonyStyle $io, Repos $repos, callable $passthru) {
  $remoteUrls = $repos->remoteUrls($remote, $urlPrefix);
  $repos->walk($remoteUrls, function ($name, $path, $remote, $url) use ($io, $passthru) {
    $io->writeln("<comment>$path</comment>: Update remote <comment>$remote</comment> (<comment>$url</comment>)");
    $passthru('git remote set-url {{0|s}} {{1|s}}', [$remote, $url]);
  });
})->setAliases(['set-remotes'])
  ->setDescription('Update parallel remotes across Civi-related repos');;

$c['app']->command("remote:fetch $globalOptions remotes*", function ($remotes, SymfonyStyle $io, Repos $repos, callable $passthru) {
  foreach ($remotes as $remote) {
    $remoteUrls = $repos->remoteUrls($remote, '!!not-applicable');
    $repos->walk($remoteUrls, function ($name, $path, $remote) use ($io, $passthru) {
      $io->writeln("[<comment>$path</comment>]: Fetch remote <comment>$remote</comment>");
      $passthru('git fetch {{0|s}}', [$remote]);
    });
  }
})->setAliases(['fetch']);

$c['app']->command("branch:create $globalOptions target source", function ($target, $source, SymfonyStyle $io, Repos $repos, callable $passthru) {
  $branchPairs = $repos->branchPairs($target, $source);
  $repos->walk($branchPairs, function ($name, $path, $tgtRemote, $tgtBranch, $srcRemote, $srcBranch) use ($io, $passthru) {
    $io->writeln("<comment>$path</comment>: Create branch <comment>$tgtRemote/$tgtBranch</comment> from <comment>$srcRemote/$srcBranch</comment>");
    $passthru('git branch {{0|s}} {{1|s}}', [$tgtBranch, "$srcRemote/$srcBranch"]);
    if ($tgtRemote) {
      $passthru('git config branch.{{0|s}}.remote {{1|s}}', [$tgtBranch, $tgtRemote]);
      $passthru('git config branch.{{0|s}}.merge refs/heads/{{1|s}}', [$tgtBranch, $tgtBranch]);
    }
  });
})->setAliases(['branch'])
  ->setDescription('Create parallel branches across Civi-related repos');

$c['app']->command("branch:update $globalOptions [--merge] [--ff-only] [--rebase] target source", function ($target, $source, SymfonyStyle $io, Repos $repos, callable $passthru, $pickMergeOpts) {
  $branchPairs = $repos->branchPairs($target, $source);
  $mergeOpts = $pickMergeOpts();

  $repos->walk($branchPairs, function ($name, $path, $tgtRemote, $tgtBranch, $srcRemote, $srcBranch) use ($io, $passthru, $mergeOpts) {
    $io->writeln("<comment>$path</comment>: Update branch <comment>$tgtRemote/$tgtBranch</comment> from <comment>$srcRemote/$srcBranch</comment>");
    assertThat($tgtRemote && $tgtBranch && $srcRemote && $srcBranch, "Target and source must be fully specified (remote/branch).");
    $params = [
      'MERGE_OPTS' => $mergeOpts,
      'TGT_BR' => $tgtBranch,
      'TGT_RM' => $tgtRemote,
      'SRC_BR' => $srcBranch,
      'SRC_RM' => $srcRemote,
    ];
    $passthru('git checkout {{TGT_BR|s}} && git pull {{MERGE_OPTS}} {{SRC_RM|s}} {{SRC_BR|s}} && git push {{TGT_RM}} {{TGT_BR}}', $params);
  });
})->setAliases(['update'])
  ->setDescription('Pull and push updates for parallel branches across Civi-related repos');

$c['app']->command("branch:pull $globalOptions [--merge] [--ff-only] [--rebase] target source", function ($target, $source, SymfonyStyle $io, Repos $repos, callable $passthru, $pickMergeOpts) {
  $branchPairs = $repos->branchPairs($target, $source);
  $mergeOpts = $pickMergeOpts();

  $repos->walk($branchPairs, function ($name, $path, $tgtRemote, $tgtBranch, $srcRemote, $srcBranch) use ($io, $passthru, $mergeOpts) {
    $io->writeln("<comment>$path</comment>: Update branch <comment>$tgtRemote/$tgtBranch</comment> from <comment>$srcRemote/$srcBranch</comment>");
    assertThat(!$tgtRemote && $tgtBranch, "Target must only specify branch name (no remote)");
    assertThat($srcRemote && $srcBranch, "Source must be fully specified (remote/branch).");
    $params = [
      'MERGE_OPTS' => $mergeOpts,
      'TGT_BR' => $tgtBranch,
      'SRC_BR' => $srcBranch,
      'SRC_RM' => $srcRemote,
    ];
    $passthru('git checkout {{TGT_BR|s}} && git pull {{MERGE_OPTS}} {{SRC_RM|s}} {{SRC_BR|s}}', $params);
  });
})->setAliases(['pull'])
  ->setDescription('Pull updates into parallel branches across Civi-related repos');

$c['app']->command("branch:push $globalOptions [-f|--force] [-u|--set-upstream] remote branch", function ($remote, $branch, $force, $setUpstream, SymfonyStyle $io, Repos $repos, callable $passthru) {
  $branches = $repos->branches("$remote/$branch");
  $repos->walk($branches, function ($name, $path, $remote, $branch) use ($io, $passthru, $force, $setUpstream) {
    $io->writeln("<comment>$path</comment>: Push branch <comment>$branch</comment> to <comment>$remote</comment>");
    $params = [
      'SETUP' => $setUpstream ? '-u' : '',
      'FORCE' => $force ? '-f' : '',
      'REMOTE' => $remote,
      'BRANCH' => $branch,
    ];
    $passthru('git push {{FORCE}} {{SETUP}} {{REMOTE|s}} {{BRANCH|s}}', $params);
  });
})->setAliases(['push']);

$c['app']->command("branch:checkout $globalOptions branch", function ($branch, SymfonyStyle $io, Repos $repos, callable $passthru) {
  $branches = array_filter($repos->branches($branch), function($b) {
      return $b['name'] !== 'drupal@6.x';
  });
  $repos->walk($branches, function ($name, $path, $remote, $branch) use ($io, $passthru) {
    $io->writeln("<comment>$path</comment>: Checkout branch <comment>$branch</comment>");
    $passthru('git checkout {{0|s}}', [$branch]);
  });
})->setAliases(['checkout'])
  ->setDescription('Checkout parallel branches across Civi-related repos');

$c['app']->command("branch:delete $globalOptions [-f|--force] branch", function ($branch, $force, SymfonyStyle $io, Repos $repos, callable $passthru) {
  $branches = $repos->branches($branch);
  $repos->walk($branches, function ($name, $path, $remote, $branch) use ($io, $passthru, $force) {
    $io->writeln("<comment>$path</comment>: Delete branch <comment>$branch</comment>");
    $mode = $force ? '-D' : '-d';
    $passthru('git show-ref --quiet refs/heads/{{1|s}} && git branch {{0|s}} {{1|s}} || echo {{2|s}}',
      [$mode, $branch, '(Ignore missing branch)']);
  });
})->setDescription('Delete parallel branches across Civi-related repos');

###############################################################################
## Utilities

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

  /**
   * @param string $remote
   * @param string $urlPrefix
   * @return array
   *   List of repos and their corresponding remotes/URLs. Each has properties: name, path, remote, url
   */
  public function remoteUrls(string $remote, string $urlPrefix): array {
    $suffix = '.git';
    return rekeyItems(['name', 'path', 'remote', 'url'], [
      ['core', '.', $remote, "{$urlPrefix}core{$suffix}"],
      ['backdrop', './backdrop', $remote, "{$urlPrefix}backdrop{$suffix}"],
      ['drupal', './drupal', $remote, "{$urlPrefix}drupal{$suffix}"],
      ['drupal-8', './drupal-8', $remote, "{$urlPrefix}drupal-8{$suffix}"],
      ['joomla', './joomla', $remote, "{$urlPrefix}joomla{$suffix}"],
      ['packages', './packages', $remote, "{$urlPrefix}packages{$suffix}"],
      ['wordpress', './WordPress', $remote, "{$urlPrefix}wordpress{$suffix}"],
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
      ['core', '.', $remote, $branch],
      ['backdrop@1.x', './backdrop', $remote, "1.x-$branch"],
      ['drupal@6.x', './drupal', $remote, "6.x-$branch"],
      ['drupal@7.x', './drupal', $remote, "7.x-$branch"],
      ['drupal-8', './drupal-8', $remote, $branch],
      ['joomla', './joomla', $remote, $branch],
      ['packages', './packages', $remote, $branch],
      ['wordpress', './WordPress', $remote, $branch],
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
      ['core', '.', $tgtRemote, $tgtBranch, $srcRemote, $srcBranch],
      ['backdrop@1.x', './backdrop', $tgtRemote, "1.x-$tgtBranch", $srcRemote, "1.x-$srcBranch"],
      ['drupal@6.x', './drupal', $tgtRemote, "6.x-$tgtBranch", $srcRemote, "6.x-$srcBranch"],
      ['drupal@7.x', './drupal', $tgtRemote, "7.x-$tgtBranch", $srcRemote, "7.x-$srcBranch"],
      ['drupal-8', './drupal-8', $tgtRemote, $tgtBranch, $srcRemote, $srcBranch],
      ['joomla', './joomla', $tgtRemote, $tgtBranch, $srcRemote, $srcBranch],
      ['packages', './packages', $tgtRemote, $tgtBranch, $srcRemote, $srcBranch],
      ['wordpress', './WordPress', $tgtRemote, $tgtBranch, $srcRemote, $srcBranch],
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

$c['passthru()'] = function (string $cmd, array $params = [], ?Cmdr $cmdr = NULL, ?InputInterface $input = NULL, ?SymfonyStyle $io = NULL) {
  $cmdDesc = '<comment>$</comment> ' . $cmdr->escape($cmd, $params) . ' <comment>[[in ' . getcwd() . ']]</comment>';
  $extraVerbosity = 0;

  if ($input->getOption('step')) {
    $extraVerbosity = OutputInterface::VERBOSITY_VERBOSE - $io->getVerbosity();
    $io->writeln($cmdDesc);
    $confirmation = ($io->ask('<info>Execute this command?</info> [<comment>Y</comment>/<comment>n</comment>/<comment>q</comment>] ', NULL, function ($value) {
      $value = ($value === NULL) ? 'y' : mb_strtolower($value);
      if (!in_array($value, ['y', 'n', 'q'])) {
        throw new InvalidArgumentException("Invalid choice ($value)");
      }
      return $value;
    }));
    switch ($confirmation) {
      case 'n':
        return;

      case 'y':
      case NULL:
        break;

      case 'q':
      default:
        throw new \Exception('User quit application');
    }
  }

  if ($input->getOption('dry-run')) {
    $io->writeln('<comment>DRY-RUN</comment>' . $cmdDesc);
    return;
  }

  try {
    $io->setVerbosity($io->getVerbosity() + $extraVerbosity);
    $cmdr->passthru($cmd, $params);
  }
  finally {
    $io->setVerbosity($io->getVerbosity() - $extraVerbosity);
  }
};

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
