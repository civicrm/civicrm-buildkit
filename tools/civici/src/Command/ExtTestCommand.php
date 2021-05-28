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


Optional environment variables:

  PHPUNIT_BIN (Name of the phpunit binary; default: phpunit7)
')
      ->addOption('dry-run', 'N', InputOption::VALUE_NONE, 'Do not execute')
      ->addOption('info', NULL, InputOption::VALUE_REQUIRED, 'Path of the XML file for the desired extension', getenv('PWD') . DIRECTORY_SEPARATOR . 'info.xml')
      ->addOption('junit-dir', NULL, InputOption::VALUE_REQUIRED, 'Folder into which JUnit XML files should be placed')
      ->addOption('timeout', NULL, InputOption::VALUE_REQUIRED, 'Max number of seconds to spend on any individual task', 600);
  }

  protected function initialize(InputInterface $input, OutputInterface $output) {
    $junitDir = $input->getOption('junit-dir');
    if ($junitDir && $junitDir{strlen($junitDir) - 1} !== DIRECTORY_SEPARATOR) {
      $junitDir .= DIRECTORY_SEPARATOR;
      $input->setOption('junit-dir', $junitDir);
    }
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

    $junitDir = $input->getOption('junit-dir');

    if ($junitDir && !file_exists($junitDir)) {
      $this->fs->mkdir($junitDir);
    }

    if (file_exists("$targetDir/phpunit.xml.dist")) {
      $phpunit = getenv('PHPUNIT_BIN') ? getenv('PHPUNIT_BIN') : 'phpunit7';
      $batch->add("<info>Restore database</info>", $restore);
      if ($phpunit !== 'phpunit5') {
        $e2eCmd = "$phpunit --printer '\Civi\Test\TAP'  --group e2e";
      }
      else {
        $e2eCmd = "$phpunit --tap --group e2e";
      }
      if ($junitDir) {
        $e2eCmd .= ' --log-junit ' . escapeshellarg("{$junitDir}e2e.xml");
      }
      $batch->add(
        "<info>Run PHPUnit group</info> (<comment>e2e</comment>)",
        new \Symfony\Component\Process\Process($e2eCmd, $targetDir)
      );

      $batch->add("<info>Restore database</info>", $restore);
      if ($phpunit !== 'phpunit5') {
        $headlessCmd = "$phpunit --printer '\Civi\Test\TAP'  --group headless";
      }
      else {
        $headlessCmd = "$phpunit --tap --group headless";
      }
      if ($junitDir) {
        $headlessCmd .= ' --log-junit ' . escapeshellarg("{$junitDir}headless.xml");
      }
      $batch->add(
        "<info>Run PHPUnit group</info> (<comment>headless</comment>)",
        new \Symfony\Component\Process\Process($headlessCmd, $targetDir)
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
