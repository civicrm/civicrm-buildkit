<?php

namespace Civici;

class DefaultExtPaths {

  public static function pick(string $buildType): string {
    if (str_starts_with($buildType, 'drupal-')) {
      return 'web/sites/default/files/civicrm/ext';
    }
    elseif (str_starts_with($buildType, 'standalone-')) {
      return 'web/ext';
    }
    elseif (str_starts_with($buildType, 'wp-')) {
      return 'web/wp-content/uploads/civicrm/ext/';
    }
    else {
      throw new \RuntimeException("Civici cannot determine default extension path for build type ($buildType)");
    }
  }

}
