#!/usr/bin/env pogo
<?php

#!ttl 10 years
#!require rubobaquero/phpquery: '^0.9.15'

########################################################################################
## General utilities

/**
 * @param string $cwd Current working directory
 * @param string $cmd Command to execute
 * @return int
 *   Exit code from command
 */
function run($cwd, $cmd) {
  $old = getcwd();
  fwrite(STDERR, "\nRUN[[$cwd]]: $cmd\n");
  chdir($cwd);
  passthru($cmd, $status);
  chdir($old);
  return $status;
}

/**
 * Print an error note.
 */
function errprintf() {
  $str = call_user_func_array('sprintf', func_get_args());
  fwrite(STDERR, $str);
}

function errdump(...$args) {
  fwrite(STDERR, var_dump($args, 1));
}

function app_usage() {
  errprintf("usage: fetch-universe <base-dir> [--dry-run] [--feeds=lab,extdir,static] [--no-deps]\n");
}

function parse_args(array $args, array $all_feeds): array {
  array_shift($args);
  $options = [
    'dryRun' => FALSE,
    'basedir' => NULL,
    'feeds' => array_keys($all_feeds),
    'deps' => TRUE,
  ];
  while (!empty($args)) {
    $arg = array_shift($args);
    if (substr($arg, 0, 2) === '--') {
      $keyValue = explode('=', substr($arg, 2), 2);
      switch ($keyValue[0]) {
        case 'dry-run':
          $options['dryRun'] = TRUE;
          break;

        case 'no-deps':
          $options['deps'] = FALSE;
          break;

        case 'feeds':
          $options['feeds'] = explode(',', $keyValue[1]);
          break;

        default:
          errprintf("Unrecognized option: $arg\n");
          exit(1);
      }
    }
    else {
      $options['basedir'] = realpath($arg);
    }
  }

  if (empty( $options['basedir'])) {
    errprintf("Missing base directory\n");
    app_usage();
    exit(1);
  }

  if (!file_exists($options['basedir']) || !is_dir($options['basedir'])) {
    errprintf("Missing base directory\n");
    app_usage();
    exit(1);
  }

  return $options;
}

########################################################################################
## Feeds

/**
 * Get the list of published extensions from civicrm.org.
 *
 * @return array
 */
function feed_extdir() {
  $extdirUrl = 'https://civicrm.org/extension-git-urls';
  // $extdirUrl = '/tmp/feed.html';
  errprintf("Fetch URL (%s)\n", $extdirUrl);
  $raw = file_get_contents($extdirUrl);

  phpQuery::newDocumentHTML($raw);
  $repos = [];
  $types = ['CiviCRM Extension' => 'ext',
    'Backdrop' => 'backdrop-module',
    'Drupal7' => 'drupal-module',
    'Drupal8' => 'drupal-module',
    'Joomla' => 'joomla-ext',
    'WordPress' => 'wp-plugin',
  ];
  foreach (pq('.egu-extension') as $row) {
    $key = trim(pq($row)->children('.egu-key')->text());
    $type = trim(pq($row)->children('.egu-type')->text());
    $url = trim(pq($row)->children('.egu-url')->text());
    if (empty($key) || empty($type) || empty($url)) {
      errprintf("Skip malformed item (key=%s, type=%s, url=%s)\n", $key, $type, $url);
      continue;
    }
    if (!isset($types[$type])) {
      throw new \Exception("Received malformed type ($type)");
    }
    $repos[$key] = [
      'title' => trim(pq($row)->children('.egu-title')->text()),
      'git_url' => $url,
      'type' => $types[$type],
    ];
  }

  return feed_normalize($repos, ['type' => 'ext']);
}

/**
 * Get the list of semi-published extensions from lab.civicrm.org.
 *
 * @return array
 */
function feed_labdir() {
  $labdir = [];
  $page = 1;
  $pageSize = 100;
  do {
    $laburl = "https://lab.civicrm.org/api/v4/groups/58/projects?page={$page}&per_page={$pageSize}";
    errprintf("Fetch URL (%s)\n", $laburl);

    $validProjectsInPage = 0;
    $projects = json_decode(file_get_contents($laburl), 1);
    foreach ($projects as $project) {
      // Have we gotten generally sensible data?
      if (empty($project['path_with_namespace'])) {
        continue;
      }

      $validProjectsInPage++;

      // Does this look cloneable?
      if (!$project['empty_repo'] && $project['repository_access_level'] !== 'disabled') {
        $name = basename($project['path_with_namespace']);
        $labdir[$name] = [
          'git_url' => $project['http_url_to_repo'],
        ];
      }
    }

    $page++;
  } while ($validProjectsInPage > 0);

  return feed_normalize($labdir, ['type' => 'ext']);
}

/**
 * Get a static list of projects from CiviCRM's Github
 * @return array
 */
function feed_static() {
  $f = require dirname(pogo_script_dir()) . '/universe.php';
  $list = $f();
  return feed_normalize($list);
}

/**
 * Adjust common quirks/omissions.
 *
 * @param array $feed
 * @return array
 */
function feed_normalize($feed, $defaults = []) {
  $new = [];
  foreach ($feed as $key => $repo) {
    if (!preg_match(';^[a-zA-Z0-9\._\-]+$;', $key)) {
      errprintf("SKIP: Malformed repo key (%s: %s)\n", $key, json_encode($key));
      continue;
    }

    $repo['key'] = $key;

    if (isset($repo['git_url']) && preg_match('/^git@(lab\.civicrm\.org|github\.com):(.*)/', $repo['git_url'], $m)) {
      $userRepo = preg_replace('/\.git$/', '', $m[2]);
      $repo['git_url'] = sprintf('https://%s/%s.git', $m[1], $userRepo);
    }
    elseif (isset($repo['git_url']) && preg_match(';^https?://(lab\.civicrm\.org|github\.com)/(.*);', $repo['git_url'], $m)) {
      $userRepo = preg_replace('/\.git$/', '', $m[2]);
      $repo['git_url'] = sprintf('https://%s/%s.git', $m[1], $userRepo);
    }

    $new[$key] = array_merge($defaults, $repo);
  }
  ksort($new);
  return $new;
}

/**
 * Combine a list of feeds.
 *
 * Duplicate keys and duplicate URLs are consolidated, with priority
 * given to the first instance.
 *
 * @param array $feeds
 * @return array
 */
function feed_merge($feeds) {
  $all = [];
  $srcIds = []; // Flag git URLs/branches that have been visited already.
  foreach ($feeds as $feed) {
    foreach ($feed as $key => $repo) {
      $srcId = ($repo['git_url'] ?? '') . ($repo['svn_url'] ?? '') . '#' . ($repo['git_branch'] ?? 'DEFAULT');
      if (isset($all[$key])) {
        errprintf("skip duplicate key (%s) from (%s)\n", $key, $srcId);
        continue;
      }
      if (isset($srcIds[$srcId])) {
        errprintf("skip duplicate src (%s) from (%s)\n", $key, $srcId);
        continue;
      }

      $all[$key] = $repo;
      $srcIds[$srcId] = 1;
    }
  }

  return feed_normalize($all);
}

########################################################################################

class TaskList {
  private $tasks = [];
  public function add(string $title, $callback) {
    $this->tasks[] = [$title, $callback];
  }
  public function runAll($dryRun = FALSE) {
    foreach ($this->tasks as $task) {
      [$title, $callback] = $task;
      if ($dryRun) {
        errprintf("DRY RUN: $title\n");
      }
      else {
        errprintf($title . "\n");
        $callback();
      }
    }
  }
}

########################################################################################
## Parse inputs

$all_feeds = [
  'extdir' => 'feed_extdir',
  'static' => 'feed_static',
  'lab' => 'feed_labdir',
];
$options = parse_args($argv, $all_feeds);
$basedir = $options['basedir'];

########################################################################################
## Main data loading

$statuses = array(); // array(string $key => int $code)
$deprecated = array('civicrm-drupal', 'civicrm-org-site', 'api4', 'civicrm-setup', 'civicrm-org-platform');

$feeds = [];
foreach ($all_feeds as $feed_name => $feed_func) {
  if (in_array($feed_name, $options['feeds'])) {
    $feeds[] = $feed_func();
  }
}
$repos = feed_merge($feeds);
$taskList = new TaskList();
$msgs = array();

foreach ($repos as $key => $ext) {
  $dir = "$basedir/" . $ext['type'] . "/$key";
  $oldDir = "$basedir/$key";

  $containerDir = dirname($dir);
  if (!is_dir($containerDir)) {
    errprintf("Init dir ($containerDir)\n");
    mkdir($containerDir);
  }

  if (is_dir($oldDir) && !is_dir($dir)) {
    $taskList->add("Move ($oldDir => $dir)", function() use ($oldDir, $dir) {
      rename($oldDir, $dir);
    });
  }

  if (empty($ext['git_url']) && empty($ext['svn_url'])) {
    $msgs[] = "$key does not have git_url or svn_url";
    $statuses[$key] = 1;
  }
  elseif (!empty($ext['git_url']) && file_exists($dir)) {
    $taskList->add("Update $key ($dir) via git", function() use ($basedir, $dir, $ext, &$statuses, $key) {
      run($dir, sprintf("git remote set-url origin %s", escapeshellarg($ext['git_url'])));
      $statuses[$key] = run($dir, "git pull");
    });
  }
  elseif (!empty($ext['git_url'])) {
    $taskList->add("Download $key ($dir) via git", function() use ($basedir, $dir, $ext, &$statuses, $key) {
      $branchExpr = empty($ext['git_branch']) ? '' : ('-b ' . escapeshellarg($ext['git_branch']));
      $statuses[$key] = run($basedir, sprintf("git clone %s %s %s", escapeshellarg($ext['git_url']), escapeshellarg($dir), $branchExpr));
    });
  }
  elseif (!empty($ext['svn_url']) && file_exists($dir)) {
    $taskList->add("Update $key ($dir) via svn", function() use ($basedir, $dir, $ext, &$statuses, $key) {
      $statuses[$key] = run($dir, "svn update");
    });
  }
  elseif (!empty($ext['svn_url'])) {
    $taskList->add("Download $key ($dir) via svn", function() use ($basedir, $dir, $ext, &$statuses, $key) {
      $statuses[$key] = run($basedir, sprintf("svn co %s %s", escapeshellarg($ext['svn_url']), escapeshellarg($dir)));
    });
  }

  if (!empty($options['deps'])) {
    $taskList->add("Resolve dependencies ($dir)", function() use ($dir, $ext, &$statuses, $key) {
      if (file_exists("$dir/composer.json") && $statuses[$key] == 0) {
        $statuses[$key] = run($dir, "composer install --no-scripts");
      }
    });
  }
}

$taskList->runAll($options['dryRun']);

foreach ($deprecated as $key) {
  $dir = "$basedir/$key";
  if (file_exists($dir)) {
    $msgs[] = "The folder \"$key\" is deprecated. Consider removing it";
  }
}

########################################################################################
$ok = array_keys(array_filter($statuses, function($val){
  return ($val == 0);
}));
$err = array_keys(array_filter($statuses, function($val){
  return ($val != 0);
}));

print_r(array(
  'ok' => $ok,
  'err' => $err,
  'msgs' => $msgs,
));
exit(array_sum($statuses));
