<?php
namespace Civi\Civibuild;
use Symfony\Component\Process\Process;

class ProcessUtil {

  /**
   * Helper which synchronously runs a command and verifies that it doesn't generate an error.
   *
   * @param \Symfony\Component\Process\Process $process
   * @return \Symfony\Component\Process\Process
   * @throws \RuntimeException
   */
  public static function runOk(\Symfony\Component\Process\Process $process) {
    if (getenv('DEBUG')) {
      var_dump(array(
        'Working Directory' => $process->getWorkingDirectory(),
        'Command' => $process->getCommandLine(),
      ));
      ob_flush();
    }

    $process->run(function ($type, $buffer) {
      if (getenv('DEBUG')) {
        if (Process::ERR === $type) {
          echo 'STDERR > ' . $buffer;
        }
        else {
          echo 'STDOUT > ' . $buffer;
        }
        ob_flush();
      }
    });
    if (!$process->isSuccessful()) {
      throw new \Civi\Civibuild\Exception\ProcessErrorException($process);
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
