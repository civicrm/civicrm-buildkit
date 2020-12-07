<?php
/**
 * Auto-generate three SSL certificates: local ca, local server, and CA bundle.
 *
 * You should generally set these two variables together:
 *
 *  - LOCO_SSL: The path where keys and certs are stored. (Default: LOCO_VAR/ssl)
 *  - LOCO_SSL_DOMAIN: Space-delimited list of DNS names to include in server cert.
 *                     May use wildcard (as long as they're valid in browsers; no TLD wildcards)
 *
 * You may optionally set:
 *
 *  - LOCO_SSL_UPSTREAM: File with a list of CA certs to pre-approve. (Default: caller's NIX_SSL_CERT_FILE or SSL_CERT_FILE)
 *
 * Creates files:
 *
 *   - LOCO_SSL/ca.key
 *   - LOCO_SSL/ca.crt
 *   - LOCO_SSL/ca-bundle.crt
 *   - LOCO_SSL/server.key
 *   - LOCO_SSL/server.crt
 *
 * Exports these variables:
 *
 *   - SSL_CERT_FILE (points to LOCO_SSL/ca-bundle.crt)
 *   - NIX_SSL_CERT_FILE (points to LOCO_SSL/ca-bundle.crt)
 */
namespace LocoSsl;

use Loco\Loco;

function loco_ssl_upstream() {
  if ($file = getenv('LOCO_SSL_UPSTREAM')) {
    return $file;
  }
  if ($file = getenv('NIX_SSL_CERT_FILE')) {
    return $file;
  }
  if ($file = getenv('SSL_CERT_FILE')) {
    return $file;
  }
  if (file_exists('/etc/ssl/certs/ca-certificates.crt')) {
    return '/etc/ssl/certs/ca-certificates.crt';
  }
  return NULL;
}

// As part of every service's initialization, run 'loco-ssl'.
Loco::dispatcher()->addListener('loco.config.filter', function($e) {
  $svcNames = array_keys($e['config']['services'] ?? []);
  foreach ($svcNames as $svcName) {
    $e['config']['services'][$svcName]['init'] = $e['config']['services'][$svcName]['init'] ?? [];
    array_unshift($e['config']['services'][$svcName]['init'], 'loco-ssl ca ca-bundle server');
  }
});

// Fill in env-vars
Loco::dispatcher()->addListener('loco.system.create', function($e) {
  $upstream = loco_ssl_upstream();
  $e['system']->default_environment->set('LOCO_SSL_UPSTREAM', $upstream);
  $e['system']->default_environment->set('LOCO_SSL', '$LOCO_VAR/ssl', TRUE);
  $e['system']->environment->set('SSL_CERT_FILE', '$LOCO_SSL/ca-bundle.crt', TRUE);
  $e['system']->environment->set('NIX_SSL_CERT_FILE', '$LOCO_SSL/ca-bundle.crt', TRUE);
});
