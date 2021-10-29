<?php


namespace Civici\Util;

class CacheDir {

  const PROGRAM = 'civici';
  const MODE = 0777;

  private static $cacheDir = NULL;

  /**
   * Get the program's cache folder.
   *
   * @param string $relPath
   *   Optionally, construct a path within the cache folder.
   *   ex: '/foo/bar'
   * @return string
   *   ex: '/home/me/.cache/civici/foo/bar'
   */
  public static function get($relPath = NULL) {
    if (self::$cacheDir === NULL) {
      self::$cacheDir = self::find();
    }
    return self::join(self::$cacheDir, $relPath);
  }

  /**
   * @param string $relPath
   * @param int $ttl
   * @return string|NULL
   */
  public static function readFile($relPath, $ttl) {
    $file = self::get($relPath);
    if (!file_exists($file) || filemtime($file) + $ttl < time()) {
      return NULL;
    }
    else {
      return file_get_contents($file);
    }
  }

  /**
   * @param string $relPath
   * @param string $data
   */
  public static function writeFile($relPath, $data) {
    $file = self::get($relPath);
    if (!is_dir(dirname($file))) {
      mkdir(dirname($file), self::MODE, TRUE);
    }
    file_put_contents($file, $data);
  }

  protected static function find() {
    if (getenv('XDG_CACHE_HOME')) {
      return self::join(getenv('XDG_CACHE_HOME'), self::PROGRAM);
    }
    if (getenv('HOME')) {
      return self::join(getenv('HOME'), '.cache', self::PROGRAM);
    }
    if (getenv('USERPROFILE')) {
      return self::join(getenv('USERPROFILE'), '.cache', self::PROGRAM);
    }
    throw new \RuntimeException('Failed to locate cache directory. Please set HOME (Unix), USERPROFILE (Windows), or XDG_CACHE_HOME (custom override).');
  }

  /**
   * Join a list of path elements. Ignore NULL/FALSE elements.
   *
   * @param mixed ...$parts
   * @return string
   */
  protected static function join(...$parts) {
    $parts = \array_filter($parts, function($part) {
      return $part !== NULL && $part !== FALSE && $part !== '';
    });
    return \implode('/', $parts);
  }

}
