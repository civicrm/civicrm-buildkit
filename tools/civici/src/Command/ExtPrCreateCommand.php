<?php
namespace Civici\Command;

use Civici\GitRepo;
use Civici\Util\ArrayUtil;
use Civici\Util\Filesystem;
use Civici\Util\Process as ProcessUtil;
use Civici\Util\Process;
use Civici\Util\ProcessBatch;
use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Input\InputOption;
use Symfony\Component\Console\Output\OutputInterface;


class ExtPrCreateCommand extends BaseCommand {

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
      ->setName('extpr:create')
      ->setDescription('Given a pull-request for an extension, prepare a test build.')
      ->setHelp('Given a pull-request for an extension, prepare a test build.

  Example: civici extpr:create https://github.com/civicrm/org.civicrm.api4/pull/123 \
    --build=pr123 --build-root=/srv/buildkit/build
      ')
      ->addOption('dry-run', 'N', InputOption::VALUE_NONE, 'Do not execute')
      ->addOption('civi-ver', NULL, InputOption::VALUE_OPTIONAL, 'CiviCRM branch or tag', 'master')
      ->addOption('build', 'b', InputOption::VALUE_REQUIRED, 'Civibuild name. Ex: "exttest"')
      ->addOption('build-root', 'r', InputOption::VALUE_REQUIRED, 'Location of the web root. Ex: /srv/buildkit/build')
      ->addOption('type', NULL, InputOption::VALUE_REQUIRED, 'Civibuild type', 'drupal-clean')
      ->addOption('keep', 'K', InputOption::VALUE_NONE, 'Do not destroy the test build')
      ->addOption('feed', NULL, InputOption::VALUE_REQUIRED, 'The URL which provides available downloads. Ex: \'https://civicrm.org/extdir/ver=5.3.0|cms=Drupal/single\', \'*auto-stable*\', \'*auto-dev*\'', '*auto-dev*')
      ->addOption('force', 'f', InputOption::VALUE_NONE, 'If an extension folder already exists, download it anyway.')
      ->addOption('timeout', NULL, InputOption::VALUE_REQUIRED, 'Max number of seconds to spend on any individual task', 600)
      ->addArgument('pr-url', InputArgument::REQUIRED, 'The local base path to search');
  }

  protected function initialize(InputInterface $input, OutputInterface $output) {
    if (!$input->getOption('build')) {
      $input->setOption('build', 'ext-' . uniqid());
    }
    $buildRoot = $input->getOption('build-root');
    if ($buildRoot && $buildRoot{strlen($buildRoot) - 1} !== DIRECTORY_SEPARATOR) {
      $buildRoot .= DIRECTORY_SEPARATOR;
      $input->setOption('build-root', $buildRoot);
    }

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

  protected function execute(InputInterface $input, OutputInterface $output) {
    if (!preg_match('/^[a-z0-9\-]+$/', $input->getOption('build'))) {
      throw new \RuntimeException("Must specify valid --build");
    }
    if (!$input->getOption('build-root')) {
      throw new \RuntimeException("Must specify valid --build-root");
    }

    $prUrl = $input->getArgument('pr-url');
    $myBuildRoot = $input->getOption('build-root') . $input->getOption('build');

    $commonParams = [
      'BLDNAME' => $input->getOption('build'),
      'MYBUILDROOT' => $myBuildRoot,
      'CIVIVER' => $input->getOption('civi-ver'),
      'TYPE' => $input->getOption('type'),
      'PRURL' => $prUrl,
      'ABSEXTROOT' => "$myBuildRoot/sites/default/files/civicrm/ext",
      'RELEXTPATH' => "sites/default/files/civicrm/ext/target",
      'ABSEXTPATH' => "$myBuildRoot/sites/default/files/civicrm/ext/target",
      'FEED' => $input->getOption('feed'),
    ];

    $batch = new ProcessBatch();

    if (file_exists($myBuildRoot)) {
      if ($input->getOption('force')) {
        $batch->add(
          '<comment>Destroy existing build (' . $input->getOption('build') . ')</comment>',
          new \Symfony\Component\Process\Process(
            Process::interpolate('echo y | civibuild destroy @BLDNAME', [
              'BLDNAME' => $input->getOption('build'),
            ])
          )
        );
      }
      else {
        $output->writeln("<error>Build already exists: $myBuildRoot</error>");
        return 1;
      }
    }

    $batch->add(
      '<comment>Download main codebase (build=' . $input->getOption('build') . ', type=' . $input->getOption('type') . ', civi-ver=' . $input->getOption('civi-ver') . ')</comment>',
      new \Symfony\Component\Process\Process(
        Process::interpolate('civibuild download @BLDNAME --type @TYPE --civi-ver @CIVIVER', $commonParams)
      )
    );
    $batch->add(
      "<comment>Download extension PR ($prUrl)</comment>",
      new \Symfony\Component\Process\Process(
        Process::interpolate('git clonepr --merged @PRURL @RELEXTPATH --depth 1', $commonParams),
        $myBuildRoot
      )
    );
    $batch->add(
      '<comment>Download extension dependencies</comment>',
      new \Symfony\Component\Process\Process(
        Process::interpolate('civici ext:dl-dep --info=@RELEXTPATH/info.xml --feed=@FEED --to=@ABSEXTROOT', $commonParams),
        $myBuildRoot
      )
    );

    $batch->add(
      '<comment>Install main database</comment>',
      new \Symfony\Component\Process\Process(
        Process::interpolate('civibuild install @BLDNAME', $commonParams),
        $myBuildRoot
      )
    );

    //$batch->add(
    //  '<comment>Install extension</comment>',
    //  new \Symfony\Component\Process\Process(
    //    Process::interpolate('cv api extension.install path=@ABSEXTPATH', $commonParams),
    //    $myBuildRoot
    //  )
    //);

    //$batch->add(
    //  '<comment>Update database snapshot</comment>',
    //  new \Symfony\Component\Process\Process(
    //    Process::interpolate('civibuild snapshot @BLDNAME', $commonParams),
    //    $myBuildRoot
    //  )
    //);

    foreach ($batch->getProcesses() as $proc) {
      /** @var \Symfony\Component\Process\Process $proc */
      $proc->setTimeout($input->getOption('timeout'));
    }

    $batch->runAllOk($output, $input->getOption('dry-run'));
  }

  /**
   * @param string $civiVer
   *   Ex: '5.3.0', '5.3', 'master'
   * @return string
   */
  protected function detectFeedUrl($civiVer, $includeDev) {
    if ($civiVer === 'master') {
      if (time() < strtotime('2021-08-01')) {
        // We don't know the real value, but (given the way forward compatibility works
        // in the feed) we can just pick something high.
        // Something like 5.99999.0 might be better, but (currently) the feed isn't very efficient
        // with really numbers.
        $feedVer = '5.40.0';
      }
      else {
        throw new \RuntimeException("Cannot fudge version lookup. Please specify --feed or a numerical --civi-ver");
      }
    }
    elseif (preg_match('/^([0-9]+\.[0-9]+)$/', $civiVer, $matches)) {
      $feedVer = $matches[1] . '.0';
    }
    elseif (preg_match('/^([0-9]+\.[0-9]+)\./', $civiVer, $matches)) {
      $feedVer = $matches[1] . '.0';
    }
    else {
      throw new \RuntimeException("Cannot autodetect extension feed for --civi-ver=$civiVer. Please specify --feed or a different --civi-ver.");
    }

    if ($includeDev) {
      return "https://civicrm.org/extdir/ver=$feedVer|uf=Bare|status=|ready=/single";
    }
    else {
      return "https://civicrm.org/extdir/ver=$feedVer|uf=Bare/single";
    }
  }

}
