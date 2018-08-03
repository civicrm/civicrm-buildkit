<?php
namespace Civici\Command;

use Civici\GitRepo;
use Civici\Util\ArrayUtil;
use Civici\Util\Filesystem;
use Civici\Util\Process as ProcessUtil;
use Civici\Util\Process;
use Civici\Util\ProcessBatch;
use GuzzleHttp\Client;
use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Input\InputOption;
use Symfony\Component\Console\Output\OutputInterface;

class ProbotStatusCommand extends BaseCommand {

  private $validStates = ['error', 'failure', 'pending', 'success'];

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
      ->setName('probot:status')
      ->setDescription('Set the status of a pull-request in probot-civicrm')
      ->setHelp('Set the status of a pull-request in probot-civicrm. This status will be relayed to Github/Gitlab.

Example: civici probot:status --probot-url="..." --probot-token="..." \
  --state=pending --url=http://foobar.com/build/123 --desc="Test running"
')
      ->addOption('dry-run', 'N', InputOption::VALUE_NONE, 'Do not execute')
      ->addOption('desc', NULL, InputOption::VALUE_REQUIRED, 'Status summary', '')
      ->addOption('url', NULL, InputOption::VALUE_REQUIRED, 'URL displaying full status information', '')
      ->addOption('state', NULL, InputOption::VALUE_REQUIRED, 'Current status (error,failure,pending,success)')
      ->addOption('probot-url', NULL, InputOption::VALUE_REQUIRED, 'Callback URL. Ex: http://user:pass@localhost:3000/probot-civicrm-ext-test/update-status')
      ->addOption('probot-token', NULL, InputOption::VALUE_REQUIRED, 'Secure token');
  }

  protected function initialize(InputInterface $input, OutputInterface $output) {
    foreach (['state', 'probot-url', 'probot-token'] as $field) {
      if (!$input->getOption($field)) {
        throw new \Exception("Missing required option: --{$field}");
      }
    }

    $state = $input->getOption('state');
    if (!in_array($state, $this->validStates)) {
      throw new \Exception("Invalid state. Use one of the following: " . implode(', ', $this->validStates));
    }
  }

  protected function execute(InputInterface $input, OutputInterface $output) {
    $params = [
      'statusToken' => $input->getOption('probot-token'),
      'state' => $input->getOption('state'),
      'description' => $input->getOption('desc'),
      'target_url' => $input->getOption('url'),
    ];
    $output->writeln(sprintf(
      "<info>Sending status</info> (<comment>state=\"%s\", target_url=\"%s\", description=\"%s\"</comment>)",
      $input->getOption('state'),
      $input->getOption('url'),
      $input->getOption('desc')
    ));
    if (!$input->getOption('dry-run')) {
      $client = new Client();
      $response = $client->post($input->getOption('probot-url'), [
        'query' => $params,
        // 'form_params' => $params,
      ]);
      $output->writeln($response->getBody()->getContents());
    }
  }

}
