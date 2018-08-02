<?php
namespace Civici\Exception;

class ProcessErrorException extends \RuntimeException {
  /**
   * @var \Symfony\Component\Process\Process
   */
  private $process;

  public function __construct(\Symfony\Component\Process\Process $process, $message = "", $code = 0, Exception $previous = NULL) {
    $this->process = $process;
    if (empty($message)) {
      $message = $this->createReport($process);
    }
    parent::__construct($message, $code, $previous);
  }

  /**
   * @param \Symfony\Component\Process\Process $process
   */
  public function setProcess($process) {
    $this->process = $process;
  }

  /**
   * @return \Symfony\Component\Process\Process
   */
  public function getProcess() {
    return $this->process;
  }

  public function createReport($process) {
    return "Process failed:
[[ COMMAND: {$process->getCommandLine()} ]]
[[ CWD: {$process->getWorkingDirectory()} ]]
[[ EXIT CODE: {$process->getExitCode()} ]]
[[ STDOUT ]]
{$process->getOutput()}
[[ STDERR ]]
{$process->getErrorOutput()}
      ";
  }

}
