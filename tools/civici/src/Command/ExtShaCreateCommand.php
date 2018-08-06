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


class ExtShaCreateCommand extends BaseCommand {

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
      ->setName('extsha:create')
      ->setDescription('Given a particular SHA for an extension, prepare a test build.')
      ->setHelp('Given a particular SHA for an extension, prepare a test build.

  Example: civici extsha:create https://github.com/totten/githubtest.git \
    --rev=4039217e8c1aa9f322aa65dc0e942c5f3880aa86 \
    --build=pr123 --build-root=/srv/buildkit/build
      ')
      ->useOptions(['build', 'build-root', 'civi-ver', 'dry-run', 'ext-dir', 'force', 'feed', 'keep', 'timeout', 'type'])
      ->addOption('rev', NULL, InputOption::VALUE_REQUIRED, 'Extension revision, identified as a git SHA')
      ->addArgument('git-url', InputArgument::REQUIRED, 'The local base path to search');
  }

  protected function execute(InputInterface $input, OutputInterface $output) {
    $myBuildRoot = $input->getOption('build-root') . $input->getOption('build');

    $commonParams = [
      'BLDNAME' => $input->getOption('build'),
      'MYBUILDROOT' => $myBuildRoot,
      'CIVIVER' => $input->getOption('civi-ver'),
      'TYPE' => $input->getOption('type'),
      'GITURL' => $input->getArgument('git-url'),
      'SHA' => $input->getOption('rev'),
      'LOCALBRANCH' => 'target',
      'ABSEXTROOT' => "$myBuildRoot/" . $input->getOption('ext-dir'),
      'RELEXTPATH' => $input->getOption('ext-dir') . "/target",
      'ABSEXTPATH' => "$myBuildRoot/" . $input->getOption('ext-dir') . "/target",
      'FEED' => $input->getOption('feed'),
    ];

    $batch = new ProcessBatch();

    if (file_exists($myBuildRoot)) {
      if ($input->getOption('force')) {
        $batch->add(
          '<info>Destroy existing build</info> (<comment>' . $input->getOption('build') . ')</comment>',
          new \Symfony\Component\Process\Process(
            Process::interpolate('echo y | civibuild destroy @BLDNAME', [
              'BLDNAME' => $input->getOption('build'),
            ])
          )
        );
      }
      else {
        throw new \RuntimeException("Build already exists: $myBuildRoot");
      }
    }

    $batch->add(
      '<info>Download main codebase</info> (<comment>build=' . $input->getOption('build') . ', type=' . $input->getOption('type') . ', civi-ver=' . $input->getOption('civi-ver') . '</comment>)',
      new \Symfony\Component\Process\Process(
        Process::interpolate('civibuild download @BLDNAME --type @TYPE --civi-ver @CIVIVER', $commonParams)
      )
    );
    $batch->add(
      "<info>Download extension</info> (<comment>{$input->getArgument('git-url')}</comment> @ <comment>{$input->getOption('rev')}</comment>)",
      new \Symfony\Component\Process\Process(
        Process::interpolate('git clone @GITURL @RELEXTPATH --no-checkout --depth 1 && cd @RELEXTPATH && git fetch origin @SHA:@LOCALBRANCH && git checkout @LOCALBRANCH', $commonParams),
        $myBuildRoot
      )
    );
    $batch->add(
      '<info>Download extension dependencies</info>',
      new \Symfony\Component\Process\Process(
        Process::interpolate('civici ext:dl-dep --info=@RELEXTPATH/info.xml --feed=@FEED --to=@ABSEXTROOT', $commonParams),
        $myBuildRoot
      )
    );

    $batch->add(
      '<info>Install main database</info>',
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

    $this->runBatch($input, $output, $batch);
  }

}
