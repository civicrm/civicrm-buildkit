<?php
namespace Civici\Command;

use Civici\GitRepo;
use Civici\Util\ArrayUtil;
use Civici\Util\Filesystem;
use Civici\Util\InfoXml;
use Civici\Util\Process as ProcessUtil;
use Civici\Util\Process;
use Civici\Util\ProcessBatch;
use Civici\Util\Xml;
use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Input\InputOption;
use Symfony\Component\Console\Output\OutputInterface;


class ExtTestCommand extends BaseCommand {

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
      ->setName('ext:test')
      ->setDescription('Given an extension, run any test suites.')
      ->setHelp('Given an extension, run any test suites.

Example:
 
  civici ext:test --info=/var/www/sites/default/civicrm/ext/org.foobar/info.xml
')
      ->addOption('dry-run', 'N', InputOption::VALUE_NONE, 'Do not execute')
      ->addOption('info', NULL, InputOption::VALUE_REQUIRED, 'Path of the XML file for the desired extension', getenv('PWD') . DIRECTORY_SEPARATOR . 'info.xml')
      ->addOption('timeout', NULL, InputOption::VALUE_REQUIRED, 'Max number of seconds to spend on any individual task', 600);
  }

  protected function initialize(InputInterface $input, OutputInterface $output) {
  }

  protected function execute(InputInterface $input, OutputInterface $output) {
    if ($input->getOption('info')) {
      if (!file_exists($input->getOption('info'))) {
        throw new \RuntimeException("File not found: " . $input->getOption('info'));
      }
      $output->writeln("<info>Parse extension info</info> (<comment>" . $input->getOption('info') . "</comment>)");
      $target = InfoXml::loadFromString(file_get_contents($input->getOption('info')));
      $targetDir = dirname($input->getOption('info'));
    }
    else {
      throw new \RuntimeException("Must specify --info");
    }

    $batch = new ProcessBatch("<info>Found extension</info> (<comment>" . $target->key . "</comment>)");

    $restore = new \Symfony\Component\Process\Process(
      Process::interpolate('civibuild restore && cv ext:enable @KEY', [
        'KEY' => $target->key,
      ]),
      $targetDir
    );

    if (file_exists("$targetDir/phpunit.xml.dist")) {
      $batch->add("<info>Restore database</info>", $restore);
      $batch->add(
        "<info>Run PHPUnit group</info> (<comment>e2e</comment>)",
        new \Symfony\Component\Process\Process('phpunit4 --tap --group e2e', $targetDir)
      );
      $batch->add("<info>Restore database</info>", $restore);
      $batch->add(
        "<info>Run PHPUnit group</info> (<comment>headless</comment>)",
        new \Symfony\Component\Process\Process('phpunit4 --tap --group headless', $targetDir)
      );
    }

    $procs = $batch->getProcesses();
    if (!$procs) {
      $output->writeln("<comment>Found no test suites</comment>");
      return 1;
    }

    foreach ($batch->getProcesses() as $proc) {
      /** @var \Symfony\Component\Process\Process $proc */
      $proc->setTimeout($input->getOption('timeout'));
    }

    $batch->runAllOk($output, $input->getOption('dry-run'));
  }

}
