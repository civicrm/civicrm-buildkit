<?php
namespace ExtTestRun\Util;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;

class Process {

  /**
   * Helper which synchronously runs a command and verifies that it doesn't generate an error.
   *
   * @param \Symfony\Component\Process\Process $process
   * @return \Symfony\Component\Process\Process
   * @throws \RuntimeException
   */
  public static function runOk(\Symfony\Component\Process\Process $process) {
    $process->run();
    if (!$process->isSuccessful()) {
      throw new \ExtTestRun\Exception\ProcessErrorException($process);
    }
    return $process;
  }

  /**
   * @param \Symfony\Component\Process\Process $process
   */
  public static function dump(\Symfony\Component\Process\Process $process) {
    var_dump(array(
      'Working Directory' => $process->getWorkingDirectory(),
      'Command' => $process->getCommandLine(),
      'Exit Code' => $process->getExitCode(),
      'Output' => $process->getOutput(),
      'Error Output' => $process->getErrorOutput(),
    ));
  }

}
