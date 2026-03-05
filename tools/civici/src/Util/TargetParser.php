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
        $split = $this->splitQuery($expr);
        return ['git-url' => $split['base'], ...$this->parseQuery($split['query'])];

      case 'lab':
      case 'hub':
        $split = $this->splitQuery($target);
        return ['git-url' => $split['base'], ...$this->parseQuery($split['query'])];

      default:
        throw new \RuntimeException('Invalid target. Expect an expression like "stable:KEY", "dev:KEY", "hub:OWNER/REPO", or "lab:OWNER/REPO"');
    }
  }

  protected function splitQuery(string $target): array {
    $parts = explode('?', $target, 2);
    return [
      'base' => $parts[0],
      'query' => $parts[1] ?? NULL,
    ];
  }

  protected function parseQuery(?string $query): array {
    if (empty($query)) {
      return [];
    }
    parse_str($query, $params);
    $allowed = ['rev', 'head', 'base'];
    foreach ($params as $key => $value) {
      if (!in_array($key, $allowed)) {
        throw new \RuntimeException("Target includes unrecognized parameter ($key)");
      }
    }
    return $params;
  }

}
