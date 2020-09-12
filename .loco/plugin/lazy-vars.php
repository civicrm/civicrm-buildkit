<?php
/**
 * The lazy-vars plugin allows you to lazily (on-demand) evaluate expensive variables.
 *
 * For example, on Google Cloud VMs, you can determine the external IP by making a web-service call.
 * This call should only run if you're actually on a Google Cloud VM where the configuration needs the external IP.
 *
 * Usage:
 * 1. In this file, update `$lazyVars['MY_VAR']` to define the callback function.
 * 2. In the 'loco.yml' file which needs to use the lazy-var, make a placeholder for the variable, e.g.
 *    `MY_VAR=(placeholder)`
 */
namespace LazyVars;

use Loco\Loco;

// --------------------------------------------------------------
// Define list of lazy variables

$GLOBALS['lazyVars']['HOSTNAME'] = function() {
  return trim(`hostname`);
};

$GLOBALS['lazyVars']['HOSTNAME_FQDN'] = function() {
  return trim(`hostname -f`);
};

$GLOBALS['lazyVars']['FAKE_IP'] = function () {
  // echo "Compute a fake IP!\n";
  return implode('.', [rand(1, 256), rand(1, 256), rand(1, 256), rand(1, 256)]);
};

$GLOBALS['lazyVars']['EXTERNAL_IP'] = function () {
  $ip = trim(file_get_contents('https://ipv4bot.whatismyipaddress.com'));
  assertWellFormedIP($ip);
  return $ip;
};

$GLOBALS['lazyVars']['GCLOUD_IP'] = function() {
  $ttl = 600;
  $ip = Loco::cache('lazy-vars')->get('gcloud-ip');
  if (!$ip) {
    $url = 'http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip';
    $opts = ['http' => ['method' => "GET", 'header' => "Metadata-Flavor: Google\r\n"]];
    $ip = file_get_contents($url, FALSE, stream_context_create($opts));
    assertWellFormedIP($ip);
    Loco::cache('lazy-vars')->set('gcloud-ip', $ip, $ttl);
  }
  return $ip;
};

// --------------------------------------------------------------
// Apply the lazy variables

function assertWellFormedIP($ip) {
  if (!$ip || !preg_match('/^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/', $ip)) {
    throw new \Exception('Failed to determine IP address. This value is not an IP address: ' . $ip);
  }
}

/**
 * Find any lazy-var placeholders and replace them.
 */
function applyLazyVars(\Loco\LocoEvent $e, \Loco\LocoEnv $env) {
  // If placeholder is defined in multiple scopes, then only compute it once.
  static $cache = [];

  foreach ($GLOBALS['lazyVars'] as $var => $callback) {
    $spec = $env->getSpec($var);
    if ($spec !== NULL) {
      $cache[$var] = $cache[$var] ?? $callback();
      $env->set($var, $cache[$var]);
    }
  }
}

Loco::dispatcher()->addListener('loco.system.create', function($e) {
  applyLazyVars($e, $e['system']->environment);
  applyLazyVars($e, $e['system']->default_environment);
});

Loco::dispatcher()->addListener('loco.service.create', function($e) {
  applyLazyVars($e, $e['service']->environment);
  applyLazyVars($e, $e['service']->default_environment);
});
