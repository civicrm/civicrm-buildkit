<?php
namespace Loco;

function _find_chrome_which(string $name, array $paths): ?string {
  foreach ($paths as $path) {
    if (file_exists("$path/$name")) {
      return "$path/$name";
    }
  }
  return NULL;
}

Loco::dispatcher()->addListener('loco.expr.functions', function (LocoEvent $e) {

  $e['functions']['find-chrome'] = function () {
    $bin = getenv('CHROME_BIN');
    if ($bin && file_exists($bin)) {
      return $bin;
    }

    $paths = explode(PATH_SEPARATOR, getenv('PATH'));

    $bin = _find_chrome_which('chromium', $paths);
    if ($bin) {
      return $bin;
    }

    $bin = _find_chrome_which('google-chrome-stable', $paths);
    if ($bin) {
      return $bin;
    }

    $paths = (array) glob("/Applications/*Chrome*/Contents/MacOS");
    $bin = _find_chrome_which('Google Chrome', $paths);
    if ($bin) {
      return $bin;
    }

    return '';
  };

});
