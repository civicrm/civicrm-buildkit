#!/usr/bin/env pogo
<?php

## The "civi-test-job" script is used to run tests on an existing branch. Some examples:
##
## $ civi-test-job --civi-ver X.Y.Z all
## $ civi-test-job --civi-ver X.Y.Z phpunit-api3 phpunit-api4
## $ use-bknix min -r civi-test-job --civi-ver X.Y.Z phpunit-e2e --type=wp-demo
## $ use-bknix max -r civi-test-job --civi-ver X.Y.Z phpunit-e2e
##
## The script can be used in a few ways:
## - In a Jenkins/GHPRB environment, it will use env-vars to choose things like "Build Name".
## - In a local/interactive environment, it will prompt for those same variables.
## - For development/inspection, you can use `--dry-run`s and `--step` wise execution.

###############################################################################
#### Imports

#!ttl 10 years
#!require clippy/std: ~0.4.3
#!require clippy/container: '~1.2'

namespace Clippy;

use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Style\SymfonyStyle;

$c = clippy()->register(plugins());

$phpunitSynopsis = '[--group=] [--exclude-group=] [--filter=]';
$phpunitValues = ['group', 'exclude-group', 'filter'];
$phpunitFlags = [];
// $phpunitSynopsis .= ' [--stop-on-defect] [--stop-on-error] [--stop-on-failure] [--stop-on-warning] [--stop-on-risky] [--stop-on-skipped] [--stop-on-incomplete] [--fail-on-warning] [--fail-on-risky]';
// $phpunitFlags = ['stop-on-defect', 'stop-on-error', 'stop-on-failure', 'stop-on-warning', 'stop-on-risky', 'stop-on-skipped', 'stop-on-incomplete', 'fail-on-warning', 'fail-on-risky'];


###############################################################################
## Main

$c['app']->command("main [-N|--dry-run] [-S|--step] [--type=] [--civi-ver=] [--keep] $phpunitSynopsis suites*", function (SymfonyStyle $io, Taskr $taskr) use ($c) {
  // First, resolve key parameters before we start composing commands. See "Key Parameters" for full details.
  [$c['buildType'], $c['buildName'], $c['buildDir'], $c['civiVer'], $c['junitDir'], $c['timeFunc'], $c['phpunitArgs']];

  $io->section("\nReport on environment");
  $taskr->passthru('civibuild env-info');

  $stopDaemons = $c['startDaemons()']();

  $io->section("\nReset working data");
  if (is_dir($c['junitDir'])) {
    $taskr->passthru('rm -rf {{0|s}}', [$c['junitDir']]);
  }
  if (is_dir($c['buildDir'])) {
    $taskr->passthru('echo y | civibuild destroy {{0|s}}', [$c['buildName']]);
  }
  $taskr->passthru('mkdir -p {{0|s}}', [$c['junitDir']]);

  $io->section("\nBuild test site");
  $taskr->passthru('civibuild download {{0|s}} --type {{1|s}} --civi-ver {{2|s}}', [
    $c['buildName'],
    $c['buildType'],
    $c['civiVer'],
  ]);
  $taskr->passthru('civibuild install {{0|s}}', [$c['buildName']]);

  $io->section("\nRun tests");
  $taskr->passthru('TIME_FUNC={{3|s}} civi-test-run -b {{0|s}} -j {{1|s}} {{2}}', [
    $c['buildName'],
    $c['junitDir'],
    implode(' ', array_map('escapeshellarg', $c['phpunitArgs'])),
    $c['timeFunc'],
  ]);

});

###############################################################################
## Key parameters

// Ex: "build-0"
$c['buildName'] = function (SymfonyStyle $io): string {
  $default = is_numeric(getenv('EXECUTOR_NUMBER')) ? ('build-' . getenv('EXECUTOR_NUMBER')) : 'build-x';
  return $io->ask('Build Name:', $default);
};

// Ex: "/home/myuser/workspace/MyJob/junit"
$c['junitDir'] = function (SymfonyStyle $io): string {
  $default = getenv('WORKSPACE') ? (getenv('WORKSPACE') . '/junit') : '/tmp/junit';
  return $io->ask('JUnit Dir:', $default);
};

// Ex: "/home/myuser/buildkit/build/build-0"
$c['buildDir'] = function (string $buildName): string {
  if (getenv('BKITBLD') && file_exists(getenv('BKITBLD'))) {
    return getenv('BKITBLD') . '/' . $buildName;
  }
  else {
    throw new \RuntimeException("Missing environment variable: BKITBLD");
  }
};

// Ex: "drupal-clean" or "wp-demo"
$c['buildType'] = function (SymfonyStyle $io, InputInterface $input) use ($c) {
  $default = $input->getOption('type');
  if (empty($default) && $input->hasOption('patch') && preg_match(';/civicrm/(civicrm-[-\w]+)/pull;', $c['patchUrl'], $m)) {
    $default = $c['defaultBuildTypes'][$m[1]] ?? NULL;
  }
  if (empty($default)) {
    $default = $c['defaultBuildTypes']['*'];
  }
  return $io->ask('Build Type', $default);
};

$c['defaultBuildTypes'] = function() {
  // If testing a PR on civicrm-* repo, we may use the repo-name to decide on the build-type.
  return [
    'civicrm-backdrop' => 'backdrop-clean',
    'civicrm-drupal-8' => 'drupal9-clean',
    'civicrm-wordpress' => 'wp-demo',
    '*' => 'drupal-clean',
  ];
};

// Ex: "5.55" or "master"
$c['civiVer'] = function (SymfonyStyle $io, InputInterface $input): string {
  if ($input->hasOption('civi-ver') && $input->getOption('civi-ver')) {
    $default = $input->getOption('civi-ver');
  }
  elseif (!empty(getenv('ghprbTargetBranch'))) {
    $default = getenv('ghprbTargetBranch');
    // TODO: Consider removing this and passing `--civi-ver=$ghprbTargetBranch`
  }
  else {
    $default = 'master';
  }

  // Repos like "civicrm-drupal" and "civicrm-backdrop" have extra "1.x-" or "7.x-".
  $default = preg_replace(';^\d.x-;', '', $default);

  $result = $io->ask('CiviCRM Version', $default);
  if (!preg_match(';^(5\.|master);', $result)) {
    throw new \Exception(sprintf('Test script does not support version "%s".', $result));
  }
  return $result;
};

// Ex: ['--exclude-group', 'ornery']
$c['phpunitArgs'] = function (InputInterface $input) use ($phpunitFlags, $phpunitValues): array {
  $opts = [];
  foreach ($phpunitFlags as $phpunitFlag) {
    if ($input->getOption($phpunitFlag)) {
      $opts[] = '--' . $phpunitFlag;
    }
  }
  foreach ($phpunitValues as $phpunitOpt) {
    if ($input->getOption($phpunitOpt) !== NULL && $input->getOption($phpunitOpt) !== '') {
      $opts[] = '--' . $phpunitOpt;
      $opts[] = $input->getOption($phpunitOpt);
    }
  }
  foreach ($input->getArgument('suites') as $suite) {
    $opts[] = $suite;
  }
  return $opts;
};

$c['timeFunc'] = function(): string {
  return 'linear:500';
};

###############################################################################
## Utilties

$c['startDaemons()'] = function() use ($c): AutoCleanup {
  $mode = getenv('CIVI_TEST_MODE');
  switch ($mode ?: '') {
    case 'loco-start-stop':
      return $c['startLocoDaemons()']();

    case '':
      return new AutoCleanup(function() {
      });

    default:
      throw new \RuntimeException('Invalid CIVI_TEST_MODE: ' . $mode);
  }
};

$c['startLocoDaemons()'] = function(SymfonyStyle $io, Taskr $taskr, InputInterface $input): AutoCleanup {
  $io->section("\nSetup daemons");
  if (!$input->getOption('keep')) {
    $taskr->passthru('loco clean');
  }
  $taskr->passthru('loco start');
  $taskr->passthru('loco-mysql-wait 60 && sleep 3'); /* experiment: saw a slow startup once, early on */
  return new AutoCleanup(function() use ($taskr, $io, $input) {
    $io->section("\nShutdown daemons");
    $taskr->passthru('loco stop');
    if (!$input->getOption('keep')) {
      $taskr->passthru('loco clean');
    }
  });
};

###############################################################################
## Go
$c['app']->setDefaultCommand('main', TRUE)->run();
