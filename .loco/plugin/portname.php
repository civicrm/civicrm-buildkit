<?php

namespace Loco;

Loco::dispatcher()->addListener('loco.expr.functions', function (LocoEvent $e) {
  $e['functions']['portname'] = function ($svc, $profile) {
    $services = [
      'http' => 8001,
      'smtp' => 1025,
      'webmail' => 1080,
      'memcache' => 12221,
      'mysql' => 3307,
      'phpfpm' => 9009,
      'redis' => 6380,
    ];
    $profiles = [
      'dfl' => 0,
      'min' => 1,
      'max' => 2,
      'edge' => 6,
    ];
    if (!isset($profiles[$profile]) || !isset($services[$svc])) {
      throw new \RuntimeException("Invalid call to 'portname $svc $profile'.");
    }
    return $services[$svc] + $profiles[$profile];
  };
});
