<?php
## When running unit-tests with paratest, we'll auto-create DBs
##
## CLI test-runner needs permission to call civibuild, but web-runtime does not

if (is_numeric(getenv('TEST_TOKEN'))) {
  /**
   * @param int $testToken
   * @return array (string $key => string $value)
   */
  function _civibuild_clone_create($testToken) {
    global $civibuild;

    $cmd = sprintf("civibuild clone-create %s/%s --clone-id %s",
      $civibuild['SITE_NAME'],
      $civibuild['SITE_ID'],
      $testToken);

    if (getenv('CIVIBUILD_CLONE_FORCE')) {
      $cmd .= ' --force';
    }

    exec($cmd, $output);

    $vars = array();
    foreach ($output as $line) {
      if (preg_match('/^- ([a-zA-Z0-9_]+): (.*)/', trim($line), $matches)) {
        $vars[$matches[1]] = $matches[2];
      }
    }
    if (empty($vars)) {
      throw new RuntimeException("Call to [$cmd] failed: " . implode("\n", $output));
    }

    $cmd = sprintf("amp datadir %s", escapeshellarg($vars['CLONE_DIR'] . '/templates_c'));
    exec($cmd, $datadir_output, $datadir_ret);
    if ($datadir_ret) {
      throw new RuntimeException("Call to [$cmd] failed: " . implode("\n", $datadir_output));
    }

    return $vars;
  }

  $cloneVars = _civibuild_clone_create(getenv('TEST_TOKEN'));
  define('CIVICRM_DSN', $cloneVars['CLONE_CIVI_DB_DSN']);
  define('CIVICRM_UF_DSN', $cloneVars['CLONE_CMS_DB_DSN']);
  // If a test-case is aggressive about smarty cleanups, then it can interfere with concurrent procs
  define('CIVICRM_TEMPLATE_COMPILEDIR', $cloneVars['CLONE_DIR'] . '/templates_c');
}
