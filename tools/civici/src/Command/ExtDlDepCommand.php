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


class ExtDlDepCommand extends BaseCommand {

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
      ->setName('ext:dl-dep')
      ->setDescription('Given an extension, download any missing dependencies.')
      ->setHelp('Given an extension, download any missing dependencies.

  Dependencies must published in the given feed.

  Example: civici ext:dl-dep \
    --info=/var/www/sites/default/civicrm/ext/org.foobar/info.xml \
    --feed=\'https://civicrm.org/extdir/ver=5.3.0|cms=Drupal/single\'

  Example: civici ext:dl-dep \
    -k org.civicrm.mosaico \
    --feed=\'https://civicrm.org/extdir/ver=5.3.0|cms=Drupal|status=|ready=/single\'

      ')
      ->addOption('dry-run', 'N', InputOption::VALUE_NONE, 'Do not execute')
      ->addOption('info', NULL, InputOption::VALUE_REQUIRED, 'Path of the XML file for the desired extension')
      ->addOption('key', 'k', InputOption::VALUE_REQUIRED, 'Key of the desired extension')
      ->addOption('feed', NULL, InputOption::VALUE_REQUIRED, 'The URL which provides available downloads. Ex: https://civicrm.org/extdir/ver=5.3.0|cms=Drupal/single')
      ->addOption('to', NULL, InputOption::VALUE_REQUIRED, 'Parent folder in which all requirements are downloaded', getenv('PWD'))
      ->addOption('force', 'f', InputOption::VALUE_NONE, 'If an extension folder already exists, download it anyway.');
  }

  protected function initialize(InputInterface $input, OutputInterface $output) {
    $to = $input->getOption('to');
    if ($to && $to[strlen($to) - 1] !== DIRECTORY_SEPARATOR) {
      $to .= DIRECTORY_SEPARATOR;
      $input->setOption('to', $to);
    }
  }

  protected function execute(InputInterface $input, OutputInterface $output) {
    if (!$input->getOption('feed')) {
      throw new \RuntimeException("Must specify valid --feed");
    }

    $output->writeln("<info>Parse extension feed \"<comment>" . $input->getOption('feed') . "</comment>\"</info>");
    $feed = $this->fetchFeed($input->getOption('feed'));

    if ($input->getOption('info') && $input->getOption('key')) {
      throw new \RuntimeException("Must specify only one of these options: --info or --key");
    }
    elseif ($input->getOption('info')) {
      if (!file_exists($input->getOption('info'))) {
        throw new \RuntimeException("File not found: " . $input->getOption('info'));
      }
      $output->writeln("<info>Parse extension info \"<comment>" . $input->getOption('info') . "\"</comment></info>");
      $target = InfoXml::loadFromString(file_get_contents($input->getOption('info')));
    }
    elseif ($input->getOption('key')) {
      if (!isset($feed[$input->getOption('key')])) {
        throw new \Exception("Cannot find information about target ({$input->getOption('key')}). Perhaps you should try a different feed?");
      }
      $target = InfoXml::loadFromString($feed[$input->getOption('key')]);
    }
    else {
      throw new \RuntimeException("Must specify --info or --key");
    }

    $requirements = $this->resolveAllRequirements($target, $feed);

    if (empty($requirements)) {
      $output->writeln("<info>No requirements found</info>");
      return 0;
    }
    $output->writeln("<info>Identified requirements:</info>\n - " . implode("\n - ", array_keys($requirements)));

    $batch = new ProcessBatch();
    foreach ($requirements as $key => $ext) {
      if (strpos($key, '..') !== FALSE || strpos($key, '/') !== FALSE) {
        throw new \Exception("Malformed $key");
      }
      $to = $this->fs->toAbsolutePath($input->getOption('to') . $key);
      if (!$input->getOption('force') && file_exists($to)) {
        $output->writeln("<info>Skip extension <comment>$key</comment>. Path already exists.</info>");
        continue;
      }
      $batch->add(
        "<info>Download <comment>$key</comment> (<comment>$ext->downloadUrl</comment>)</info>",
        \Symfony\Component\Process\Process::fromShellCommandline(
          Process::interpolate('cv dl @MODE -b @EXPR --to=@TO', [
            'MODE' => $input->getOption('force') ? '--force' : '--keep',
            'TO' => $to,
            'EXPR' => $key . '@' . $ext->downloadUrl,
          ])
        )
      );
    }

    $batch->runAllOk($output, $input->getOption('dry-run'));
  }

  /**
   * @param string $feedUrl
   * @return mixed|null
   * @throws \Exception
   */
  protected function fetchFeed($feedUrl) {
    $json = file_get_contents($feedUrl);
    $feed = $json ? json_decode($json, 1) : NULL;
    if (empty($json) || empty($feed)) {
      throw new \Exception("Feed URL does not return a valid feed: " . $feedUrl);
    }
    return $feed;
  }

  /**
   * @param InfoXml $target
   * @param array $feed
   *   array(string $extKey => string $xml).
   * @return array
   *   Array(string $extKey => InfoXml $info).
   */
  protected function resolveAllRequirements($target, $feed) {
    $todos = $target->requires;
    $visited = [$target->key => 1];

    while (count($todos)) {
      $requiredKey = array_shift($todos);
      if (isset($visited[$requiredKey])) {
        continue;
      }

      if (!isset($feed[$requiredKey])) {
        throw new \Exception("Cannot find information about requirement ($requiredKey). Perhaps you should try a different feed?");
      }

      $ext = InfoXml::loadFromString($feed[$requiredKey]);
      $todos = array_merge($todos, $ext->requires);
      $visited[$requiredKey] = $ext;
    }
    unset($visited[$target->key]);
    ksort($visited);
    return $visited;
  }

}
