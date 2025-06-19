<?php
namespace Loco;

Loco::dispatcher()->addListener('loco.expr.functions', function (LocoEvent $e) {

  $e['functions']['civi-domain'] = function ($ip) {
    $ip = trim($ip);
    if (empty($ip) || $ip === '127.0.0.1') {
      return 'local.civi.bid';
    }
    else {
      $ip = str_replace('.', '-', $ip);
      return $ip . '.ip.civi.bid';
    }
  };

});
