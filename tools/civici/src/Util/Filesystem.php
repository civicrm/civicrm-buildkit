<?php
namespace Civici\Util;

class Filesystem extends \Symfony\Component\Filesystem\Filesystem {
  /**
   * @param string $path
   * @return string updated $path
   */
  public function toAbsolutePath($path) {
    if (empty($path)) {
      $res = getcwd();
    }
    elseif ($this->isAbsolutePath($path)) {
      $res = $path;
    }
    else {
      $res = getcwd() . DIRECTORY_SEPARATOR . $path;
    }
    if (is_dir($res)) {
      return realpath($res);
    }
    else {
      return $res;
    }
  }

  /**
   * @param array $paths of string
   * @return array updated paths
   */
  public function toAbsolutePaths($paths) {
    $result = array();
    foreach ($paths as $path) {
      $result[] = $this->toAbsolutePath($path);
    }
    return $result;
  }

  public function isDescendent($child, $parent) {
    $parent = rtrim($parent, DIRECTORY_SEPARATOR) . DIRECTORY_SEPARATOR;
    $child = rtrim($child, DIRECTORY_SEPARATOR) . DIRECTORY_SEPARATOR;
    if (strlen($parent) >= strlen($child)) {
      return FALSE;
    }
    return ($parent == substr($child, 0, strlen($parent)));
  }

  public function formatPrettyPath($path, $basePaths) {
    foreach ($basePaths as $basePath) {
      if ($path == $basePath || $this->isDescendent($path, $basePath)) {
        return rtrim($this->makePathRelative($path, dirname($basePath)), '/');
      }
    }
    return $path;
  }

  public function findFirstParent($path, $basePaths) {
    foreach ($basePaths as $basePath) {
      if ($path == $basePath || $this->isDescendent($path, $basePath)) {
        return $basePath;
      }
    }
    return NULL;
  }

  /**
   * @param string|array|Traversable $files
   * @throws \RuntimeException
   */
  public function validateExists($files) {
    if (!$files instanceof \Traversable) {
      $files = new \ArrayObject(is_array($files) ? $files : array($files));
    }

    //foreach ($this->toIterator($files) as $file) {
    foreach ($files as $file) {
      if (!file_exists($file)) {
        throw new \RuntimeException("File not found: $file");
      }
    }
  }

}
