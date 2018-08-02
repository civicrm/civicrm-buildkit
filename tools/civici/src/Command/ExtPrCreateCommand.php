<?php
namespace Civici\Command;

use Civici\GitRepo;
use Civici\Util\ArrayUtil;
use Civici\Util\Filesystem;
use Civici\Util\Process as ProcessUtil;
use Civici\Util\Process;
use Civici\Util\ProcessBatch;
use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Input\InputOption;
use Symfony\Component\Console\Output\OutputInterface;


class ExtPrCreateCommand extends BaseCommand {

  /**
   * @var Filesystem
   */
  var $fs;

  /**
   * @param string|NULL $name
   */
  public function __construct($name = NULL) {
    $this->fs = new Filesystem();
    parent::__construct($name);
  }

  protected function configure() {
    $this
      ->setName('extpr:create')
      ->setDescription('Given a pull-request for an extension, prepare a test build.')
      ->setHelp('Given a pull-request for an extension, prepare a test build.

  Example: civici extpr:create https://github.com/civicrm/org.civicrm.api4/pull/123 \
    --build pr123 --build-root /srv/buildkit/build
      ')
      ->addOption('dry-run', 'N', InputOption::VALUE_NONE, 'Do not execute')
      ->addOption('civi-ver', NULL, InputOption::VALUE_OPTIONAL, 'CiviCRM branch or tag', 'master')
      ->addOption('build', 'b', InputOption::VALUE_REQUIRED, 'Civibuild name. Ex: "exttest"')
      ->addOption('build-root', 'r', InputOption::VALUE_REQUIRED, 'Location of the web root. Ex: /srv/buildkit/build')
      ->addOption('type', NULL, InputOption::VALUE_REQUIRED, 'Civibuild type', 'drupal-clean')
      ->addOption('keep', 'K', InputOption::VALUE_NONE, 'Do not destroy the test build')
      ->addArgument('pr-url', InputArgument::REQUIRED, 'The local base path to search');
  }

  protected function initialize(InputInterface $input, OutputInterface $output) {
    if (!$input->getOption('build')) {
      $input->setOption('build', 'ext-' . uniqid());
    }
    $buildRoot = $input->getOption('build-root');
    if ($buildRoot && $buildRoot{strlen($buildRoot)-1} !== DIRECTORY_SEPARATOR) {
      $buildRoot .= DIRECTORY_SEPARATOR;
      $input->setOption('build-root', $buildRoot);
    }
  }

  protected function execute(InputInterface $input, OutputInterface $output) {
    if (!preg_match('/^[a-z0-9\-]+$/', $input->getOption('build'))) {
      throw new \RuntimeException("Must specify valid --build");
    }
    if (!$input->getOption('build-root')) {
      throw new \RuntimeException("Must specify valid --build-root");
    }

    $extPath = 'sites/default/civicrm/ext/target';
    $prUrl = $input->getArgument('pr-url');
    $batch = new ProcessBatch('<comment>Build and execute test for ' . $prUrl . '</comment>');
    $batch->add(
      '<comment>Build empty site</comment>',
      new \Symfony\Component\Process\Process(
        Process::interpolate('civibuild download @BLD --type drupal-clean --civi-ver @CIVIVER', [
          'BLD' => $input->getOption('build'),
          'CIVIVER' => $input->getOption('civi-ver'),
        ])
      )
    );
    $batch->add(
      '<comment>Clone extension</comment>',
      new \Symfony\Component\Process\Process(
        Process::interpolate('git clonepr @URL @EXTPATH --depth 1', [
          'URL' => $prUrl,
          'EXTPATH' => $extPath,
        ]),
        $input->getOption('build-root') . $input->getOption('build')
      )
    );
    $batch->runAllOk($output, $input->getOption('dry-run'));
  }

}
