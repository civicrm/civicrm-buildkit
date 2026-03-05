<?php

namespace Civici\Util;

class TargetParser {

  public function parse(string $target): array {
    [$type, $expr] = explode(':', $target, 2);
    switch ($type) {
      case 'stable':
      case 'dev':
        return ['key' => $expr, 'feed' => strtoupper($type)];

      case 'git':
        return ['git-url' => $expr];

      case 'lab':
      case 'hub':
        return ['git-url' => $target];

      default:
        throw new \RuntimeException('Invalid target. Expect an expression like "stable:KEY", "dev:KEY", "hub:OWNER/REPO", or "lab:OWNER/REPO"');
    }
  }

}
