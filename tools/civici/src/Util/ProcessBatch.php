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

  /**
   * @param \Symfony\Component\Console\Output\OutputInterface $output
   * @param bool $dryRun
   */
  public function runAllOk(OutputInterface $output, $dryRun = FALSE) {
    if ($this->tasks) {
      if ($this->title) {
        $output->writeln("<comment>{$this->title}</comment>");
      }
      foreach ($this->tasks as $task) {
        list ($label, $command) = $task;
        /** @var \Symfony\Component\Process\Process $command */
        $output->writeln($label);
        if (!$dryRun) {
          Process::runOk($command);
        }
        else {
          $output->writeln("\$ cd " . escapeshellarg($command->getWorkingDirectory()));
          $output->writeln("\$ " . $command->getCommandLine());
        }
      }
      $output->writeln("<comment>Done.</comment>");
    }
    else {
      $output->writeln("<comment>Nothing to do</comment>");
    }
  }

}
