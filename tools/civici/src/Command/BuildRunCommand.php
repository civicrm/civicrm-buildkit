<?php
namespace ExtTestRun\Command;

use ExtTestRun\GitRepo;
use ExtTestRun\Util\ArrayUtil;
use ExtTestRun\Util\Filesystem;
use ExtTestRun\Util\Process as ProcessUtil;
use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Input\InputOption;
use Symfony\Component\Console\Output\OutputInterface;


class BuildRunCommand extends BaseCommand {

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
      ->setName('build-run')
      ->setDescription('Build a site. Include the extension and its dependencies.')
      ->setHelp('Create a list of git repos. This may be useful for piping and shell scripting.

      Example: git scan ls | while read dir; do ls -la $dir ; done
      ')
      ->addOption('absolute', 'A', InputOption::VALUE_NONE, 'Output absolute paths')
      ->addArgument('ext-repo', InputArgument::IS_ARRAY, 'The local base path to search', array(getcwd()));
  }

  protected function initialize(InputInterface $input, OutputInterface $output) {
  }

  protected function execute(InputInterface $input, OutputInterface $output) {
    $output->writeln("<info>Hello world</info>");
  }

}
