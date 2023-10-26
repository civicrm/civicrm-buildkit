<?php

namespace Loco;

Loco::dispatcher()->addListener('loco.expr.functions', function (LocoEvent $e) {
  $e['functions']['which'] = function ($name) {
    $paths = explode(PATH_SEPARATOR, getenv('PATH'));
    foreach ($paths as $path) {
      if (file_exists("$path/$name")) {
        return "$path/$name";
      }
    }
    return '';
  };
});
