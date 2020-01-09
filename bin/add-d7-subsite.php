#!/usr/bin/env pogo
<?php
## About: Add a subsite.
## Note: This is not a swiss-army knife of "add any subsite you might want". It's one-off script.
## Issues: Only works on Apache VDR. Subdomain names can have conflicts.
#!depdir ../app/tmp/add-d7-subsite
#!require clippy/std: ~0.2.0
namespace Clippy;

require_once pogo_script_dir() . '/../src/civibuild.show.php';

$c = clippy()->register(plugins());
$c['app']->main('buildName subDomain [--vdr]', function ($buildName, $subDomain, $vdr, $io) {
  $site = civibuild_show($buildName);
  $subUrl = subdomainUrl($site['CMS_URL'], $subDomain);
  $subHostname = parse_url($subUrl, PHP_URL_HOST);
  $io->writeln("<info>Creating <comment>$subUrl</comment> as a sub-site under <comment>{$site['CMS_ROOT']}/sites/$subHostname</comment></info>");

  // Kludge: Do we use Apache Virtual Document Root?
  if ($vdr) {
    // -- Add vhost --
    chdir(dirname($site['WEB_ROOT']));
    if (!file_exists($subDomain)) {
      mkdir($subDomain);
    }
    chdir($subDomain);
    if (!is_link('web')) {
      symlink($site['CMS_ROOT'], 'web');
    }
    $subdirWebRoot = trim(`pwd`) . '/web';

    // -- Setup DB --
    chdir($site['CMS_ROOT']);
    $created = parseSh(execOk(cmdf('amp create -f -N%s --skip-url', $subDomain)));
    print_r(['Created database' => $created]);
  }
  else {
    // Add vhost + DB --
    chdir($site['CMS_ROOT']);
    $created = parseSh(execOk(cmdf('amp create -f -N%s --url=%s', $subDomain, $subUrl)));
    print_r(['Created database' => $created]);
    $subdirWebRoot = $site['CMS_ROOT'];
  }

  // -- Setup D7 + Civi --
  passthruOk(cmdf('drush site-install -y --site-name=%s --sites-subdir=%s --db-url=%s --account-name=%s --account-pass=%s --account-mail=%s',
    $subHostname, $subHostname, $created['AMP_DB_DSN'], $site['ADMIN_USER'], $site['ADMIN_PASS'], $site['ADMIN_EMAIL']));

  passthruOk(cmdf('chmod u+w sites/%s', $subHostname));

  $installCmd = cmdf('cd %s && cv core:install -f --hostname=%s --cms-base-url=%s', "$subdirWebRoot/sites/$subHostname", $subHostname, $subUrl);
  passthruOk("$installCmd --debug-model");
  passthruOk("$installCmd");
  // Note: we set "cd %s" s.t. detected file-paths match the file-paths used by the webserver.
});

// ---------------------------------------------------------------------------

/**
 * Edit $url, injecting a prefix to the domain.
 */
function subdomainUrl($url, $subdomain) {
  $oldHost = parse_url($url, PHP_URL_HOST);
  $newHost = $subdomain . '.' . $oldHost;
  // FIXME could be better
  return str_replace($oldHost, $newHost, $url);
}

function cmdf($cmd) {
  $args = func_get_args();
  $sprintf = [array_shift($args)];
  foreach ($args as $arg) {
    $sprintf[] = escapeshellarg($arg);
  }
  return call_user_func_array('sprintf', $sprintf);
}

function execOk($cmd) {
  fprintf(STDERR, "EXEC: [%s]\n", $cmd);
  exec($cmd, $output, $ret);
  if ($ret !== 0) {
    throw new \Exception("Command failed: $cmd");
  }
  return $output;
}

function passthruOk($cmd) {
  fprintf(STDERR, "PASSTHRU: [%s]\n", $cmd);
  passthru($cmd, $ret);
  if ($ret !== 0) {
    throw new \Exception("Command failed: $cmd");
  }
}

function parseSh($lines) {
  $result = [];
  foreach ($lines as $line) {
    if (preg_match('/^([A-Z0-9_]+)=\'(.*)\'$/', $line, $matches)) {
      $result[$matches[1]] = stripcslashes($matches[2]);
    }
    else {
      throw new \Exception("Malformed line: $line");
    }
  }
  return $result;
}
