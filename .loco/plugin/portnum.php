<?php

namespace Loco;

Loco::dispatcher()->addListener('loco.expr.functions', function (LocoEvent $e) {
  $e['functions']['portnum'] = function ($base, $group, $offset = 0) {
    if (!is_numeric($base) || !is_numeric($group) || !is_numeric($offset)) {
      throw new \RuntimeException("Invalid call to 'portnum $base $group $offset'. Three integers expected.");
    }
    return $base + (100 * $group) + $offset;
  };
});
