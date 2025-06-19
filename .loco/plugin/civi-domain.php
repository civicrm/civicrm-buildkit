<?php
namespace Loco;

Loco::dispatcher()->addListener('loco.expr.functions', function (LocoEvent $e) {

  $e['functions']['civi-domain'] = function ($ip) {
    $ip = trim($ip);

    // There are two options here.
    //
    // `*.local.civi.bid`: For most deployments with `127.0.0.1`, we use a
    // simpler and prettier wildcard.  It can be easily supported by common
    // DNS infra.
    //
    // `*.ip.civi.bid`: The IP-based wildcard is a more general and elegant
    // solution, but it needs some specialized DNS ops (e.g.  pdns-pipe) and
    // relies on gratis/unsupported hosting.  It's prone to random
    // de-commissioning every 4 years.  (It can be re-built, but there will
    // be lag.)

    if (empty($ip) || $ip === '127.0.0.1') {
      return 'local.civi.bid';
    }
    else {
      $ip = str_replace('.', '-', $ip);
      return $ip . '.ip.civi.bid';
    }
  };

});
