<?php

namespace Civici;

use Civici\Util\InfoXml;

class Feed {

  protected string $url;

  protected ?array $data = NULL;

  /**
   * @param string $url
   */
  public function __construct(string $url) {
    $this->url = $url;
  }

  public function getAll(): array {
    $this->data ??= $this->fetch();
    return $this->data;
  }

  public function getInfo(string $key): ?string {
    return $this->getAll()[$key] ?? NULL;
  }

  protected function fetch() {
    $json = file_get_contents($this->url);
    $feed = $json ? json_decode($json, 1) : NULL;
    if (empty($json) || empty($feed)) {
      throw new \Exception("Feed URL does not return a valid feed: " . $this->url);
    }
    return $feed;
  }

  /**
   * @param \Civici\Util\InfoXml $target
   * @return array
   *   Array(string $extKey => InfoXml $info).
   */
  public function resolveAllRequirements($target) {
    $feed = $this->getAll();

    $todos = $target->requires;
    $visited = [$target->key => 1];

    while (count($todos)) {
      $requiredKey = array_shift($todos);
      if (isset($visited[$requiredKey])) {
        continue;
      }

      if (!isset($feed[$requiredKey])) {
        throw new \Exception("Cannot find information about requirement ($requiredKey). Perhaps you should try a different feed?");
      }

      $ext = InfoXml::loadFromString($feed[$requiredKey]);
      $todos = array_merge($todos, $ext->requires);
      $visited[$requiredKey] = $ext;
    }
    unset($visited[$target->key]);
    ksort($visited);
    return $visited;
  }

}
