<?php
namespace Civici\Util;

use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;

class ProcessBatch {

  private $title;

  private $tasks = array();

  /**
   * ProcessBatch constructor.
   * @param $title
   */
  public function __construct($title = NULL) {
    $this->title = $title;
  }

  /**
   * @param string $label
   * @param \Symfony\Component\Process\Process $command
   * @return $this
   */
  public function add($label, \Symfony\Component\Process\Process $command) {
    $this->tasks[] = array($label, $command);
    return $this;
  }

  public function getProcesses() {
    $result = [];
    foreach ($this->tasks as $task) {
      $result[] = $task[1];
    }
    return $result;
  }

  /**
   * @param \Symfony\Component\Console\Output\OutputInterface $output
   * @param bool $dryRun
   */
  public function runAllOk(OutputInterface $output, $dryRun = FALSE) {
    if ($this->tasks) {
      if ($this->title) {
        $output->writeln("<comment>{$this->title}</comment>");
      }

      $oldDebugLevel = getenv('DEBUG');
      if ($output->getVerbosity() >= OutputInterface::VERBOSITY_VERY_VERBOSE) {
        putenv('DEBUG=1');
      }

      foreach ($this->tasks as $task) {
        list ($label, $command) = $task;
        /** @var \Symfony\Component\Process\Process $command */
        $output->writeln($label);

        if ($output->getVerbosity() == OutputInterface::VERBOSITY_VERBOSE) {
          $output->writeln("\$ cd " . escapeshellarg($command->getWorkingDirectory()));
          $output->writeln("\$ " . $command->getCommandLine());
        }

        if (!$dryRun) {
          Process::runOk($command);
        }
      }

      putenv("DEBUG=$oldDebugLevel");

      $output->writeln("<info>Done.</info>");
    }
    else {
      $output->writeln("<comment>Nothing to do</comment>");
    }
  }

}
