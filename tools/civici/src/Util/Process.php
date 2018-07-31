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
  public static function runDebug($process) {
    if (getenv('DEBUG')) {
      var_dump(array(
        'Working Directory' => $process->getWorkingDirectory(),
        'Command' => $process->getCommandLine(),
      ));
      //      ob_flush();
    }

    $process->run(function ($type, $buffer) {
      if (getenv('DEBUG')) {
        if (\Symfony\Component\Process\Process::ERR === $type) {
          echo 'STDERR > ' . $buffer;
        }
        else {
          echo 'STDOUT > ' . $buffer;
        }
        // ob_flush();
      }
    });

    return $process;
  }

  /**
   * Helper which synchronously runs a command and verifies that it doesn't generate an error.
   *
   * @param \Symfony\Component\Process\Process $process
   * @return \Symfony\Component\Process\Process
   * @throws \RuntimeException
   */
  public static function runOk(\Symfony\Component\Process\Process $process) {
    self::runDebug($process);
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

  public static function interpolate($expr, $args) {
    if ($args === NULL) {
      return $expr;
    }
    else {
      return preg_replace_callback('/([#!@])([a-zA-Z0-9_]+)/', function($m) use ($args) {
        if (isset($args[$m[2]])) {
          $values = $args[$m[2]];
        }
        else {
          // Unrecognized variables are ignored. Mitigate risk of accidents.
          return $m[0];
        }
        $values = is_array($values) ? $values : array($values);
        switch ($m[1]) {
          case '@':
            return implode(', ', array_map('escapeshellarg', $values));

          case '!':
            return implode(', ', $values);

          case '#':
            foreach ($values as $valueKey => $value) {
              if ($value === NULL) {
                $values[$valueKey] = 'NULL';
              }
              elseif (!is_numeric($value)) {
                //throw new API_Exception("Failed encoding non-numeric value" . var_export(array($m[0] => $values), TRUE));
                throw new Exception("Failed encoding non-numeric value (" . $m[0] . ")");
              }
            }
            return implode(', ', $values);

          default:
            throw new Exception("Unrecognized prefix");
        }
      }, $expr);
    }
  }

}
