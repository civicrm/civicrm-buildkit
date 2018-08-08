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


class ExtBuildCommand extends BaseCommand {

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
      ->setName('ext:build')
      ->setDescription('Given a SHA or pull-request for an extension, prepare a test build.')
      ->setHelp('Given a SHA or pull-request for an extension, prepare a test build.

  Example: civici ext:build --git-url=https://github.com/civicrm/org.civicrm.api4 \
    --rev=abcd1234 --build-root=/srv/buildkit/build

  Example: civici ext:build --git-url=https://github.com/civicrm/org.civicrm.api4 \
    --base=abcd1234 --head=abcd1234 --build-root=/srv/buildkit/build
  
  Example: civici ext:build --pr-url=https://github.com/civicrm/org.civicrm.api4/pull/123 \
    --build=pr123 --build-root=/srv/buildkit/build
      ')
      ->useOptions(['build', 'build-root', 'civi-ver', 'dry-run', 'ext-dir', 'force', 'feed', 'keep', 'timeout', 'type'])
      ->addOption('pr-url', NULL, InputOption::VALUE_REQUIRED, 'The local base path to search')
      ->addOption('rev', NULL, InputOption::VALUE_REQUIRED, 'Git SHA/branch/tag')
      ->addOption('base', NULL, InputOption::VALUE_REQUIRED, 'Base revision -- Git SHA/branch/tag; Combine with --head')
      ->addOption('head', NULL, InputOption::VALUE_REQUIRED, 'Head revision -- Git SHA/branch/tag; Combine with --base')
      ->addOption('git-url', NULL, InputOption::VALUE_REQUIRED, 'The local base path to search');
  }

  protected function initialize(InputInterface $input, OutputInterface $output) {
    parent::initialize($input, $output);

    $impliedRequirements = [
      'base' => ['head', 'git-url'],
      'head' => ['base', 'git-url'],
    ];
    foreach ($impliedRequirements as $by => $requirements) {
      foreach ($requirements as $requirement) {
        if ($input->getOption($by) && !$input->getOption($requirement)) {
          throw new \RuntimeException("Option --{$by} requires --{$requirement}");
        }
      }
    }
  }

  protected function execute(InputInterface $input, OutputInterface $output) {
    $prUrl = $input->getOption('pr-url');
    $myBuildRoot = $input->getOption('build-root') . $input->getOption('build');

    $commonParams = [
      'BLDNAME' => $input->getOption('build'),
      'MYBUILDROOT' => $myBuildRoot,
      'CIVIVER' => $input->getOption('civi-ver'),
      'TYPE' => $input->getOption('type'),
      'PRURL' => $prUrl,
      'GITURL' => $input->getOption('git-url'),
      'SHA' => $input->getOption('rev'),
      'BASE_SHA' => $input->getOption('base'),
      'HEAD_SHA' => $input->getOption('head'),
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
        $output->writeln("<error>Build already exists: $myBuildRoot</error>");
        return 1;
      }
    }

    $batch->add(
      '<info>Download main codebase</info> (<comment>build=' . $input->getOption('build') . ', type=' . $input->getOption('type') . ', civi-ver=' . $input->getOption('civi-ver') . '</comment>)',
      new \Symfony\Component\Process\Process(
        Process::interpolate('civibuild download @BLDNAME --type @TYPE --civi-ver @CIVIVER', $commonParams)
      )
    );

    if ($input->getOption('pr-url')) {
      $batch->add(
        "<info>Download extension PR</info> (<comment>$prUrl</comment>)",
        new \Symfony\Component\Process\Process(
          Process::interpolate('git clonepr --merged @PRURL @RELEXTPATH --depth 1', $commonParams),
          $myBuildRoot
        )
      );
    }
    elseif ($input->getOption('git-url') && $input->getOption('rev')) {
      $batch->add(
        "<info>Download extension</info> (<comment>{$input->getOption('git-url')}</comment> @ <comment>{$input->getOption('rev')}</comment>)",
        new \Symfony\Component\Process\Process(
          Process::interpolate('git clone @GITURL @RELEXTPATH --no-checkout --depth 1 && cd @RELEXTPATH && git fetch origin @SHA:@LOCALBRANCH && git checkout @LOCALBRANCH', $commonParams),
          $myBuildRoot
        )
      );
    }
    elseif ($input->getOption('git-url') && $input->getOption('base') && $input->getOption('head')) {
      $batch->add(
        "<info>Download extension</info> (<comment>{$input->getOption('git-url')}</comment> @ {$input->getOption('base')} + {$input->getOption('head')})",
        new \Symfony\Component\Process\Process(
          Process::interpolate('git clonebh @GITURL @RELEXTPATH @BASE_SHA @HEAD_SHA', $commonParams),
          $myBuildRoot
        )
      );
    }
    elseif ($input->getOption('git-url')) {
      $batch->add(
        "<info>Download extension</info> (<comment>{$input->getOption('git-url')}</comment> @ default branch)",
        new \Symfony\Component\Process\Process(
          Process::interpolate('git clone @GITURL @RELEXTPATH --depth 1', $commonParams),
          $myBuildRoot
        )
      );
    }
    else {
      throw new \RuntimeException("Must specify --pr-url or --git-url");
    }

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
