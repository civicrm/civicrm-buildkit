<?php

namespace Civici;

class GitUrl {

  public static function normalize(?string $url): ?string {
    if ($url === NULL) {
      return $url;
    }
    elseif (preg_match(';^hub:([\w\.\-]+)/([\w\.\-]+)(\.git)?$;', $url, $matches)) {
      return 'https://github.com/' . $matches[1] . '/' . $matches[2] . '.git';
    }
    elseif (preg_match(';^lab:([\w\.\-]+)/([\w\.\-]+)(\.git)?$;', $url, $matches)) {
      return 'https://lab.civicrm.org/' . $matches[1] . '/' . $matches[2] . '.git';
    }
    else {
      return $url;
    }
  }

}
