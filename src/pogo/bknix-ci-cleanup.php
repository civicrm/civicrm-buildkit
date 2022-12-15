#!/usr/bin/env pogo
<?php
#!ttl 10 years
#!require symfony/var-dumper: ~3.0|~4.4
#!require symfony/yaml: ~3.0|~4.4
#!require clippy/std: ~0.3.4
namespace Clippy;

use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\Console\Style\SymfonyStyle;
use Symfony\Component\Process\Process;
use Symfony\Component\Yaml\Yaml;

$c = clippy()->register(plugins());

###############################################################################
## About
##
## The ci-cleanup script aims to keep available capacity within certain boundaries.
## To meet those boundaries, it will perform a series of increasingly aggressive cleanup tasks.
##
## - Initially, it runs the "level 0" tasks.
##   Ex: Delete files older than 2 weeks.
## - If there still isn't enough free space, then proceed to "level 1" tasks.
##   Ex: Delete files older than 1 week.
## - If there still isn't enough, then proceed to "level 2". Ad nauseum.

###############################################################################
## Primary subcommands

$c['app']->command('dump', function($allTasks) {
  dump([
    'partitions' => uniq(...array_column($allTasks, 'partitions')),
    'levels' => uniq(array_column($allTasks, 'level')),
    'tasks' => $allTasks,
  ]);
});

$c['app']->command('run [-N|--dry-run] [--threshold=]', function($dryRun, $threshold, SymfonyStyle $io, $allTasks, $findTasks, $isPartitionFull, $cmdr) {
  if (empty($threshold)) {
    $threshold = 90;
  }
  $exitCode = 0;
  $partitions = uniq(...array_column($allTasks, 'partitions'));
  $levels = uniq(array_column($allTasks, 'level'));

  $io->writeln("<comment>PARTITIONS</comment>: <info>" . implode("</info>, <info>", $partitions) . "</info> (" . count($partitions) . ")");
  $io->writeln("<comment>THRESHOLD</comment>: <info>" . $threshold . "%</info>");

  // Whiddle the $partitions. In each pass, we run the next level of (relevant) cleanups and remove any satisfactory partitions.
  // Repeat until either (a) all partitions are satisfactory or (b) there are no more relevant cleanups.
  while (TRUE) {
    $partitions = array_filter($partitions, function($p) {
      return file_exists($p);
    });
    $level = array_shift($levels);

    $io->writeln("Clean up level <info>{$level}</info> on partitions <info>" . implode("</info>, <info>", $partitions) . "</info>.");
    $tasks = $findTasks(['level' => $level, 'partitions' => $partitions]);
    foreach (uniq(array_column($tasks, 'cmd')) as $cmd) {
      if ($dryRun) {
        $io->writeln("<comment>DRY-RUN</comment>: " . $cmd);
      }
      else {
        $cmdr->passthru($cmd, NULL);
      }
    }

    $partitions = array_filter($partitions, function($p) use ($isPartitionFull, $threshold) {
      return $isPartitionFull($p, $threshold);
    });
    if (empty($partitions)) {
      $io->writeln("<comment>COMPLETE</comment>: All partitions meet the <info>" . $threshold . "%</info> threshold.");
      break;
    }
    if (empty($levels)) {
      $io->writeln("<error>Cannot reduce space to {$threshold}%. No more levels found.</error>");
      $exitCode = 1;
      break;
    }
  }

  return $exitCode;
});

###############################################################################
## Task library

class CleanupTask {

  /**
   * How early/late to try this cleanup task.
   *
   * Lower levels run first. If they don't succeed in creating sufficient
   * free space, then higher levels run.
   *
   * @var int
   */
  public $level = 0;

  /**
   * A bash command which frees up some space.
   *
   * @var string|null
   */
  public $cmd = NULL;

  /**
   * List of paths from which files may be removed.
   *
   * @var string[]
   */
  public $paths = [];

  /**
   * List of partitions from which files may be removed.
   * Usually computed from $paths.
   *
   * @var string[]
   */
  public $partitions = [];

  /**
   * Optional bash command. The rule is only used if the command returns success.
   *
   * @var string|null
   */
  public $condition = NULL;
}

/**
 * @return CleanupTask[]
 */
$c['allTasks'] = function($createTask, $cmdr, $ymlConfig) {
  /** @var CleanupTask[] $tasks */
  $tasks = [];

  foreach ($ymlConfig['tasks'] ?? [] as $taskSpec) {
    $newTasks = $createTask($taskSpec);
    foreach ($newTasks as $task) {
      if ($task->condition !== NULL && $task->condition !== '') {
        /** @var Process $proc */
        $proc = $cmdr->process($task->condition);
        $proc->run();
        if (!$proc->isSuccessful()) {
          continue;
        }
      }
      $tasks[] = $task;
    }
  }

  usort($tasks, function($a, $b){
    return $a->level - $b->level;
  });

  return $tasks;
};

/**
 * @return array
 *   The aggregated YAML configuration
 */
$c['ymlConfig'] = function($io) {

  $glob = dirname(pogo_script_dir(), 2) . '/app/bknix-ci-cleanup.d/*.yml';
  $files = (array) glob($glob);
  if (empty($files)) {
    throw new \RuntimeException("Failed to find configuration files: $glob");
  }

  $ymlConfig = ['templates' => [], 'templateSets' => [], 'tasks' => []];
  foreach ($files as $file) {
    $io->writeln("<comment>PARSING</comment>: Config file <info>$file</info>");
    $yml = Yaml::parse(file_get_contents($file));

    // Propagate file-scoped vars
    if (isset($yml['vars'])) {
      foreach ($yml['tasks'] as &$task) {
        $task['vars'] = array_merge($yml['vars'], $task['vars'] ?? []);
      }
    }

    // Merge into main list
    $ymlConfig['templates'] = array_merge($ymlConfig['templates'] ?? [], $yml['templates'] ?? []);
    $ymlConfig['templateSets'] = array_merge($ymlConfig['templateSets'] ?? [], $yml['templateSets'] ?? []);
    $ymlConfig['tasks'] = array_merge($ymlConfig['tasks'] ?? [], $yml['tasks'] ?? []);
  }

  return $ymlConfig;
};

/**
 * @param array $params
 * @param callable $getPartition
 *   (injected)
 * @param SymfonyStyle $io
 *   (injected)
 * @param array $ymlConfig
 * @param Cmdr $cmdr
 * @return \Clippy\CleanupTask[]
 */
$c['createTask()'] = function($params, $getPartition, SymfonyStyle $io, $ymlConfig, $cmdr) use ($c) {

  if (isset($params['templateSet'])) {
    if (!isset($ymlConfig['templateSets'][$params['templateSet']])) {
      throw new \RuntimeException("Unrecognized templateSet: " . $params['templateSet']);
    }
    $newTasks = [];
    foreach ($ymlConfig['templateSets'][$params['templateSet']] as $template) {
      $newTaskParams = $template;
      $newTaskParams['vars'] = array_merge($template['vars'] ?? [], $params['vars'] ?? []);
      $newTasks = array_merge(
        $c['createTask()']($newTaskParams, $getPartition, $io, $ymlConfig, $cmdr),
        $newTasks
      );
    }
    return $newTasks;
  }

  if (isset($params['template'])) {
    if (!isset($ymlConfig['templates'][$params['template']])) {
      throw new \RuntimeException("Unrecognized template: " . $params['template']);
    }
    $params = array_merge($ymlConfig['templates'][$params['template']], $params);
    unset($params['template']);
  }

  $vars = $params['vars'] ?? [];
  unset($params['vars']);

  $task = new CleanupTask($params);
  foreach ($params as $k => $v) {
    switch ($k) {
      case 'level':
        // No filtering needed.
        break;

      case 'cmd':
      case 'condition':
        $v = $cmdr->escape($v, $vars);
        break;

      case 'paths':
      case 'partitions':
        foreach ($v as &$item) {
          $item = $cmdr->escape($item, $vars);
        }
        break;
    }
    $task->{$k} = $v;
  }

  $partitions = [];
  foreach ($task->paths as $path) {
    $part = $getPartition(realpath($path));
    if ($part) {
      $partitions[] = $part;
    }
  }
  $task->partitions = uniq($partitions);

  return [$task];
};

/**
 * @param array $criteria
 *   partition: string
 *   level: int
 * @param CleanupTask[] $allTasks
 *   (injected)
 * @return array
 *   List of tasks, filtered by $criteria.
 */
$c['findTasks()'] = function($criteria, $allTasks) {
  return array_filter($allTasks, function($t) use ($criteria) {
    /** @var CleanupTask $t */
    if (isset($criteria['partition']) && !in_array($criteria['partition'], $t->partitions)) {
      return FALSE;
    }
    if (isset($criteria['partitions']) && empty(array_intersect($criteria['partitions'], $t->partitions))) {
      return FALSE;
    }
    if (isset($criteria['level']) && $t->level != $criteria['level']) {
      return FALSE;
    }
    return TRUE;
  });
};

###############################################################################
## Partition helpers

/**
 * Determine the root mount-point for the partition which has $tgtPath.
 *
 * Ambiguity: if there are symlinks, do you care about the partition where the
 * symlink lives or the partition where (ultimate) the symlink-target lives? Use
 * `$getPartition(realpath(...))` if you need the target.
 *
 * @param string $tgtPath
 *   Ex: '/home/foo/.bashrc'
 * @param Cmdr $cmdr
 *   (injected)
 * @return string
 *   Ex: '/home' or '/'
 */
$c['getPartition()'] = function($tgtPath, Cmdr $cmdr) {
  $withSlash = function($x) {return rtrim($x, '/') . '/'; };

  static $partitions = NULL;
  if ($partitions === NULL) {
    $partitions = explode("\n", $cmdr->run('df --out=target | grep -v "^Mounted on"'));
    foreach ($partitions as &$p) {
      $p = $withSlash($p);
    }
  }

  $tgtPath = $withSlash($tgtPath);
  $bestMatch = NULL;
  foreach ($partitions as $partition) {
    if (strpos($tgtPath, $partition) === 0) {
      if ($bestMatch === NULL || strlen($bestMatch) < strlen($partition)) {
        $bestMatch = $partition;
      }
    }
  }

  return $bestMatch === '/' ? '/' : rtrim($bestMatch, '/');
};

/**
 * Determine if a partition's utilization is approaching it's capacity.
 *
 * @param string $tgtPath
 * @param int $maxUsedPct
 *  The threshold percentage. If more than $X percent used, then the disk needs work.
 * @param \Clippy\Cmdr $cmdr
 *   (injected)
 * @return bool
 * @throws \Exception
 */
$c['isPartitionFull()'] = function($tgtPath, $maxUsedPct, Cmdr $cmdr) {
  $inodePct = trim($cmdr->run('df {{TGT|s}} --output=ipcent | tail -n1 | sed \'s/[^0-9]//g\'', ['TGT' => $tgtPath]));
  $spacePct = trim($cmdr->run('df {{TGT|s}} --output=pcent | tail -n1 | sed \'s/[^0-9]//g\'', ['TGT' => $tgtPath]));
  if (!is_numeric($inodePct) || !is_numeric($spacePct)) {
    throw new \Exception("Received invalid percentages ($spacePct, $inodePct)");
  }
  return ($inodePct > $maxUsedPct || $spacePct > $maxUsedPct);
};

###############################################################################
## Primitive utilities

/**
 * Combine the $arrays and return the uniq values.
 *
 * @param \array[] ...$arrays
 * @return array
 *   Unique values.
 *   To avoid ambiguous behavior, these values are sorted (natsort).
 */
function uniq(array... $arrays) {
  $v = [];
  foreach ($arrays as $arr) {
    $v = array_unique(array_merge($arr, $v));
  }
  $v = array_values($v);
  natsort($v);
  return $v;
}

###############################################################################
$c['app']->run();
