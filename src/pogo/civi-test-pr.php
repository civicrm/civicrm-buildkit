#!/usr/bin/env pogo
<?php

###############################################################################
#### Imports

#!ttl 10 years
#!require clippy/std: ~0.3.5
#!require clippy/container: '~1.2'

namespace Clippy;

use Symfony\Component\Console\Exception\InvalidArgumentException;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\Console\Style\SymfonyStyle;

$c = clippy()->register(plugins());

$phpunitSynopsis = '[--group=] [--exclude-group=] [--filter=]';
$phpunitValues = ['group', 'exclude-group', 'filter'];
$phpunitFlags = [];
// $phpunitSynopsis .= ' [--stop-on-defect] [--stop-on-error] [--stop-on-failure] [--stop-on-warning] [--stop-on-risky] [--stop-on-skipped] [--stop-on-incomplete] [--fail-on-warning] [--fail-on-risky]';
// $phpunitFlags = ['stop-on-defect', 'stop-on-error', 'stop-on-failure', 'stop-on-warning', 'stop-on-risky', 'stop-on-skipped', 'stop-on-incomplete', 'fail-on-warning', 'fail-on-risky'];

###############################################################################
## Main

$c['app']->command("main [-N|--dry-run] [-S|--step] [--type=] [--patch=] $phpunitSynopsis suites*", function (SymfonyStyle $io, callable $passthru) use ($c) {
  // Resolve these values before we start composing commands.
  [$c['buildType'], $c['buildName'], $c['buildDir'], $c['civiVer'], $c['patchUrl'], $c['junitDir'], $c['timeFunc'], $c['phpunitArgs']];

  if (!preg_match(';^(5\.|master);', $c['civiVer'])) {
    $io->writeln(sprintf('Test script does not support version <comment>%s</comment>.', $c['civiVer']));
    return 1;
  }

  if (is_dir($c['junitDir'])) {
    $passthru('rm -rf {{0|s}}', [$c['junitDir']]);
  }
  if (is_dir($c['buildDir'])) {
    $passthru('echo y | civibuild destroy {{0|s}}', [$c['buildName']]);
  }
  $passthru('mkdir -p {{0|s}}', [$c['junitDir']]);

  $passthru('civibuild env-info');
  $passthru('civibuild download {{0|s}} --type {{1|s}} --civi-ver {{2|s}} --patch {{3|s}}', [
    $c['buildName'],
    $c['buildType'],
    $c['civiVer'],
    $c['patchUrl'],
  ]);

  $passthru('civibuild install {{0|s}}', [$c['buildName']]);

  $passthru('TIME_FUNC={{3|s}} civi-test-run -b {{0|s}} -j {{1|s}} {{2}}', [
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
  $default = getenv('EXECUTOR_NUMBER') ? ('build-' . getenv('EXECUTOR_NUMBER')) : 'build-x';
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

$c['passthru()'] = function (string $cmd, array $params = [], ?Cmdr $cmdr = NULL, ?InputInterface $input = NULL, ?SymfonyStyle $io = NULL) {
  $cmdDesc = '<comment>$</comment> ' . $cmdr->escape($cmd, $params) . ' <comment>[[in ' . getcwd() . ']]</comment>';
  $extraVerbosity = 0;

  if ($input->getOption('step')) {
    $extraVerbosity = OutputInterface::VERBOSITY_VERBOSE - $io->getVerbosity();
    $io->writeln('<comment>COMMAND</comment>' . $cmdDesc);
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


###############################################################################
## Go
$c['app']->setDefaultCommand('main', TRUE)->run();
