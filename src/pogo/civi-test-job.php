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
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\Console\Style\SymfonyStyle;
use Symfony\Component\Process\Process;

$c = clippy()->register(plugins());

$phpunitSynopsis = '[--group=] [--exclude-group=] [--filter=]';
$phpunitValues = ['group', 'exclude-group', 'filter'];
$phpunitFlags = [];

###############################################################################
## Main

$c['app']->command("main [-N|--dry-run] [-S|--step] [--type=] [--civi-ver=] [--loco] [--keep] $phpunitSynopsis suites*", function (SymfonyStyle $io, Taskr $taskr, bool $loco, Cmdr $cmdr) use ($c) {
  // Resolve these values before we start composing commands.
  [$c['buildType'], $c['buildName'], $c['buildDir'], $c['civiVer'], $c['junitDir'], $c['timeFunc'], $c['phpunitArgs']];

  if (!preg_match(';^(5\.|master);', $c['civiVer'])) {
    $io->writeln(sprintf('Test script does not support version <comment>%s</comment>.', $c['civiVer']));
    return 1;
  }

  $io->section("\nReport on environment");
  $taskr->passthru('civibuild env-info');

  if ($loco) {
    $stopLoco = $c['locoStart()']();
    // $stopLoco = $c['locoRun()']();
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

$c['civiVer'] = function (SymfonyStyle $io, InputInterface $input): string {
  $default = $input->getOption('civi-ver') ? $input->getOption('civi-ver') : 'master';
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

$c['locoRun()'] = function(SymfonyStyle $io, Taskr $taskr, Cmdr $cmdr, InputInterface $input, OutputInterface $output): AutoCleanup {
  $io->section("\nSetup daemons");
  if (!$input->getOption('keep')) {
    $taskr->passthru('loco clean');
  }
  if ($input->getOption('dry-run')) {
    $io->writeln('<comment>DRY-RUN$</comment> loco run');
    $daemons = NULL;
  }
  else {
    $daemons = $cmdr->process('loco run');
    $daemons->start(function($type, $buffer) use ($output) {
      $stream = (Process::ERR === $type) ? STDERR : STDOUT;
      fwrite($stream, $buffer);
      fflush($stream);
    });
  }
  $taskr->passthru('loco-mysql-wait 300 && sleep 5');
  return new AutoCleanup(function() use ($taskr, $io, $daemons, $input) {
    $io->section("\nShutdown daemons");
    if ($input->getOption('dry-run')) {
      $io->writeln('<comment>DRY-RUN$</comment> loco run <comment>[Ctrl-C]</comment>');
    }
    else {
      $daemons->stop(30, SIGINT);
    }

    $taskr->passthru($input->getOption('keep') ? 'loco stop' : 'loco clean');
  });
};

$c['locoStart()'] = function(SymfonyStyle $io, Taskr $taskr, InputInterface $input): AutoCleanup {
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
