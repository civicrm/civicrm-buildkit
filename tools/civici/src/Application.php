<?php
namespace Civici;
use LesserEvil\ShellVerbosityIsEvil;
use Symfony\Component\Console\Input\ArrayInput;
use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Input\InputOption;
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\DependencyInjection\ContainerBuilder;

class Application extends \Symfony\Component\Console\Application {

  /**
   * Primary entry point for execution of the standalone command.
   */
  public static function main($binDir) {
    $application = new Application('civici', '@package_version@');
    $application->run();
  }

  public function __construct($name = 'UNKNOWN', $version = 'UNKNOWN') {
    parent::__construct($name, $version);
    $this->setCatchExceptions(TRUE);
    $this->addCommands($this->createCommands());
  }

  /**
   * Construct command objects
   *
   * @return array of Symfony Command objects
   */
  public function createCommands() {
    $commands = array();
    $commands[] = new \Civici\Command\ExtDlDepCommand();
    $commands[] = new \Civici\Command\ExtTestCommand();
    $commands[] = new \Civici\Command\ExtBuildCommand();
    $commands[] = new \Civici\Command\ProbotStatusCommand();
    return $commands;
  }

  protected static function isPhar() {
    return preg_match(';^phar:;', __FILE__);
  }

  protected function configureIO(InputInterface $input, OutputInterface $output) {
    ShellVerbosityIsEvil::doWithoutEvil(function() use ($input, $output) {
      parent::configureIO($input, $output);
    });
  }

}
