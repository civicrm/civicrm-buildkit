#!/usr/bin/env pogo
<?php

## The "civi-test-pr" script is used to run a PR tests. Some examples:
##
## $ civi-test-pr --patch=https://github.com/civicrm/civicrm-core/pull/1234 all
## $ civi-test-pr --patch=https://github.com/civicrm/civicrm-core/pull/1234 phpunit-api3 phpunit-api4
## $ use-bknix min -r civi-test-pr --patch=https://github.com/civicrm/civicrm-core/pull/1234 phpunit-e2e --type=wp-demo
## $ use-bknix max -r civi-test-pr --patch=https://github.com/civicrm/civicrm-core/pull/1234 phpunit-e2e
##
## The script can be used in a few ways:
## - In a Jenkins/GHPRB environment, it will use env-vars to choose things like "CiviCRM Version" and "Build Name".
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

$c['app']->command("main [-N|--dry-run] [-S|--step] [--type=] [--patch=] [--loco] $phpunitSynopsis suites*", function (SymfonyStyle $io, Taskr $taskr, bool $loco, Cmdr $cmdr) use ($c) {
  // Resolve these values before we start composing commands.
  [$c['buildType'], $c['buildName'], $c['buildDir'], $c['civiVer'], $c['patchUrl'], $c['junitDir'], $c['timeFunc'], $c['phpunitArgs']];

  if (!preg_match(';^(5\.|master);', $c['civiVer'])) {
    $io->writeln(sprintf('Test script does not support version <comment>%s</comment>.', $c['civiVer']));
    return 1;
  }

  $io->section("\nReport on environment");
  $taskr->passthru('civibuild env-info');

  if ($loco) {
    $io->section("\nSetup daemons");
    $taskr->passthru("loco start -f"); /* force - if someone left old/dirty configs, overwrite them */
    $stopLoco = new AutoCleanup(function() use ($taskr, $io) {
      $io->section("\nShutdown daemons");
      $taskr->passthru("loco stop");
      $taskr->passthru("loco clean");
    });
  }

  $io->section("\nReset working data");
  if (is_dir($c['junitDir'])) {
    $taskr->passthru('rm -rf {{0|s}}', [$c['junitDir']]);
  }
  if (is_dir($c['buildDir'])) {
    $taskr->passthru('echo y | civibuild destroy {{0|s}}', [$c['buildName']]);
  }
  $taskr->passthru('mkdir -p {{0|s}}', [$c['junitDir']]);

  $io->section("\nBuild test site");
  $taskr->passthru('civibuild download {{0|s}} --type {{1|s}} --civi-ver {{2|s}} --patch {{3|s}}', [
    $c['buildName'],
    $c['buildType'],
    $c['civiVer'],
    $c['patchUrl'],
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

$c['patchUrl'] = function (InputInterface $input, SymfonyStyle $io) use ($c): string {
  $default = $input->getOption('patch');
  $patchUrl = $io->ask('PR URL:', $default);
  if (!preg_match(';^https://github\.com/civicrm/[a-z0-9\-]+/pull/\d+/?$;', $patchUrl)) {
    throw new \RuntimeException("Malformed PR URL");
  }
  return $patchUrl;
};

$c['buildName'] = function (SymfonyStyle $io): string {
  $default = is_numeric(getenv('EXECUTOR_NUMBER')) ? ('build-' . getenv('EXECUTOR_NUMBER')) : 'build-x';
  return $io->ask('Build Name:', $default);
};

$c['junitDir'] = function (SymfonyStyle $io): string {
  $default = getenv('WORKSPACE') ? (getenv('WORKSPACE') . '/junit') : '/tmp/junit';
  return $io->ask('JUnit Dir:', $default);
};

$c['buildDir'] = function (string $buildName): string {
  if (getenv('BKITBLD') && file_exists(getenv('BKITBLD'))) {
    return getenv('BKITBLD') . '/' . $buildName;
  }
  else {
    throw new \RuntimeException("Missing environment variable: BKITBLD");
  }
};

$c['buildType'] = function (SymfonyStyle $io, InputInterface $input) {
  $default = $input->getOption('type') ? $input->getOption('type') : 'drupal-clean';
  return $io->ask('Build Type', $default);
};

$c['civiVer'] = function (SymfonyStyle $io): string {
  $default = getenv('ghprbTargetBranch') ? getenv('ghprbTargetBranch') : 'master';
  return $io->ask('CiviCRM Version', $default);
};

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
#### Helpers

# Nevermind, all our helpers went upstream!

###############################################################################
## Go
$c['app']->setDefaultCommand('main', TRUE)->run();
