<?php
namespace Civici\Command;

use Civici\Util\CacheDir;
use Symfony\Component\Console\Command\Command;
use Civici\Util\ProcessBatch;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Input\InputOption;
use Symfony\Component\Console\Output\OutputInterface;

class BaseCommand extends Command {

  const MASTER_VERSION_URL = 'https://raw.githubusercontent.com/civicrm/civicrm-core/master/xml/version.xml';

  const CACHE_TTL = 60 * 60;

  /**
   * @param array $names
   *   List of standard options to enable.
   * @return $this
   */
  protected function useOptions($names) {
    foreach ($names as $name) {
      switch ($name) {
        case 'build-root':
          $this->addOption('build-root', 'r', InputOption::VALUE_REQUIRED, 'Location of the web root. Ex: /srv/buildkit/build');
          break;

        case 'build':
          $this->addOption('build', 'b', InputOption::VALUE_REQUIRED, 'Civibuild name. Ex: "exttest"');
          break;

        case 'civi-ver':
          $this->addOption('civi-ver', NULL, InputOption::VALUE_OPTIONAL, 'CiviCRM branch or tag', 'master');
          break;

        case 'dry-run':
          $this->addOption('dry-run', 'N', InputOption::VALUE_NONE, 'Do not execute');
          break;

        case 'ext-dir':
          $this->addOption('ext-dir', NULL, InputOption::VALUE_REQUIRED, 'Relative path to the extension dir', 'web/sites/default/files/civicrm/ext');
          break;

        case 'feed':
          $this->addOption('feed', NULL, InputOption::VALUE_REQUIRED, 'The URL which provides available downloads. Ex: \'https://civicrm.org/extdir/ver=5.3.0|cms=Drupal/single\', \'*auto-stable*\', \'*auto-dev*\'', '*auto-dev*');
          break;

        case 'force':
          $this->addOption('force', 'f', InputOption::VALUE_NONE, 'If an extension folder already exists, download it anyway.');
          break;

        case 'keep':
          $this->addOption('keep', 'K', InputOption::VALUE_NONE, 'Do not destroy the test build');
          break;

        case 'timeout':
          $this->addOption('timeout', NULL, InputOption::VALUE_REQUIRED, 'Max number of seconds to spend on any individual task', 600);
          break;

        case 'type':
          $this->addOption('type', NULL, InputOption::VALUE_REQUIRED, 'Civibuild type', 'drupal-clean');
          break;

      }
    }
    return $this;
  }

  protected function initialize(InputInterface $input, OutputInterface $output) {
    $def = $this->getDefinition();

    if ($def->hasOption('build')) {
      if (!$input->getOption('build')) {
        $input->setOption('build', 'ext-' . uniqid());
      }
      if (!preg_match('/^[a-z0-9\-]+$/', $input->getOption('build'))) {
        throw new \RuntimeException("Must specify valid --build");
      }
    }

    if ($def->hasOption('build-root')) {
      $buildRoot = $input->getOption('build-root');
      if ($buildRoot && $buildRoot[strlen($buildRoot) - 1] !== DIRECTORY_SEPARATOR) {
        $buildRoot .= DIRECTORY_SEPARATOR;
        $input->setOption('build-root', $buildRoot);
      }
      if (!$input->getOption('build-root')) {
        throw new \RuntimeException("Must specify valid --build-root");
      }
    }

    if ($this->getDefinition()->hasOption('feed')) {
      $feed = $input->getOption('feed');
      switch ($feed) {
        case '':
        case '*auto-stable*':
          $feed = $this->detectFeedUrl($input->getOption('civi-ver'), FALSE);
          $input->setOption('feed', $feed);
          break;

        case '*auto-dev*':
          $feed = $this->detectFeedUrl($input->getOption('civi-ver'), TRUE);
          $input->setOption('feed', $feed);
          break;

        default:
          break;
      }
    }
  }

  /**
   * @param string $civiVer
   *   Ex: '5.3.0', '5.3', 'master'
   * @param bool $includeDev
   *   Whether to include development extension releases (alphas/betas).
   * @return string
   */
  protected function detectFeedUrl($civiVer, $includeDev) {
    $feedVer = NULL;
    if ($civiVer === 'master') {
      $feedVer = CacheDir::readFile('master-version.txt', self::CACHE_TTL);
      if ($feedVer === NULL) {
        $xmlString = file_get_contents(self::MASTER_VERSION_URL);
        $xmlObj = simplexml_load_string($xmlString);
        $feedVer = preg_replace('/^(\d+\.\d+)\..*$/', '\1.0', (string) $xmlObj->version_no);
        CacheDir::writeFile('master-version.txt', $feedVer);
      }
    }
    elseif (preg_match('/^([0-9]+\.[0-9]+)$/', $civiVer, $matches)) {
      $feedVer = $matches[1] . '.0';
    }
    elseif (preg_match('/^([0-9]+\.[0-9]+)\./', $civiVer, $matches)) {
      $feedVer = $matches[1] . '.0';
    }

    if ($feedVer === NULL) {
      throw new \RuntimeException("Cannot autodetect extension feed for --civi-ver=$civiVer. Please specify --feed or a different --civi-ver. Alternatively, you may need to fix the Internet connection or clear the civici cache dir.");
    }

    if ($includeDev) {
      return "https://civicrm.org/extdir/ver=$feedVer|uf=Bare|status=|ready=/single";
    }
    else {
      return "https://civicrm.org/extdir/ver=$feedVer|uf=Bare/single";
    }
  }

  /**
   * @param \Symfony\Component\Console\Input\InputInterface $input
   * @param \Symfony\Component\Console\Output\OutputInterface $output
   * @param $batch
   */
  protected function runBatch(InputInterface $input, OutputInterface $output, ProcessBatch $batch) {
    foreach ($batch->getProcesses() as $proc) {
      /** @var \Symfony\Component\Process\Process $proc */
      $proc->setTimeout($input->getOption('timeout'));
    }

    $batch->runAllOk($output, $input->getOption('dry-run'));
  }

}
