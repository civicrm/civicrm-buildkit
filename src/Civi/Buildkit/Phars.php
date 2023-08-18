<?php

namespace Civi\Buildkit;

class Phars {

  /**
   * @param array $task
   *   Ex: ['phar-json' => 'path/to/my.json', 'file-mode' => ]
   */
  public static function downloadPhars(array $task) {
    if (empty($task['phar-json']) || !file_exists($task['phar-json'])) {
      throw new \RuntimeException(sprintf("Invalid phar-json file (%s, relative to %s)",
        $task['phar-json'] ?? '',
        getcwd()
      ));
    }

    $phars = json_decode(file_get_contents($task['phar-json']), 1);
    if (empty($phars)) {
      throw new \RuntimeException(sprintf("phar-json file (%s) does not define any valid JSON records",
        $task['phar-json']
      ));
    }

    // static::printf("%s\n", print_r(['phars' => $phars], 1));
    $todos = static::findUpdates($phars);
    // static::printf("%s\n", print_r(['todos' => $todos], 1));
    foreach ($todos as $name => $todo) {
      static::printf("  - Download %s (%s)\n", $todo['buildkit-path'], $todo['url']);
      static::downloadFile($todo['url'], $todo['sha256'], $todo['buildkit-path']);
      chmod($todo['buildkit-path'], intval($todo['file-mode'] ?? '0755', 8));
    }
  }

  /**
   * Show a printfing. Accepts printf()-style parameters.
   */
  protected static function printf($expr, ...$args): void {
    fprintf(STDERR, $expr, ...$args);
  }

  /**
   * @param array $phars
   *   List of PHARs from `phars.json`, e.g.
   *   ['cv' => ['url' => ..., 'sha256' => ..., 'buildkit-path' => ...]]
   * @return array
   *   The same list, filtered downe to items that actually need updates.
   */
  protected static function findUpdates(array $phars): array {
    $todos = [];
    foreach ($phars as $name => $phar) {
      if (empty($phar['buildkit-path'])) {
        continue;
      }
      if (!file_exists($phar['buildkit-path'])) {
        $todos[$name] = $phar + ['why' => 'does not exist'];
        continue;
      }
      $hash = hash_file('sha256', $phar['buildkit-path'], FALSE);
      if (!static::validateChecksum($phar['sha256'], $hash)) {
        $todos[$name] = $phar + ['why' => 'wrong checksum'];
      }
    }
    return $todos;
  }

  /**
   * Download a file. Verify the checksum before putting it into its final position.
   *
   * @throws \Exception
   */
  protected static function downloadFile(string $remoteUrl, string $expectHash, string $localFile, int $blockSize = 65536): void {
    if (is_dir($localFile)) {
      static::printf("    WARNING: Cannot overwrite folder (%s) with file. Skip download.\n", $localFile);
      // This should arguably be fatal... I'm not sure it's going to bubble-up
      return;
    }

    $parent = dirname($localFile);
    if (!is_dir($parent)) {
      if (!mkdir($parent, 0755, TRUE)) {
        throw new \Exception("Failed to initialize folder ($parent)");
      }
    }

    $tempFile = dirname($localFile) . DIRECTORY_SEPARATOR . '.tmp-' . md5(time() . mt_rand()) . basename($localFile);

    $hashCtx = hash_init('sha256');

    $remoteHandle = fopen($remoteUrl, 'rb');
    if (!$remoteHandle) {
      throw new \Exception("Failed to open remote URL for reading.");
    }

    $tempHandle = fopen($tempFile, 'wb');
    if (!$tempHandle) {
      fclose($remoteHandle);
      throw new \Exception("Failed to create temp file for writing.");
    }

    while (!feof($remoteHandle)) {
      $chunk = fread($remoteHandle, $blockSize);
      fwrite($tempHandle, $chunk);
      hash_update($hashCtx, $chunk);
    }

    fclose($remoteHandle);
    fclose($tempHandle);
    $actualHash = hash_final($hashCtx);

    if (!static::validateChecksum($expectHash, $actualHash)) {
      unlink($tempFile);
      throw new \Exception(sprintf("Download for \"%s\" failed SHA-256 check (expect=%s, actual=%s)", $remoteUrl, $expectHash, $actualHash));
    }

    // Civix could be a directory if checked out as a repo (unusual but possible configuration).
    if (file_exists($localFile)) {
      unlink($localFile);
    }

    if (!rename($tempFile, $localFile)) {
      throw new \Exception("Failed to move temp file to destination.");
    }
  }

  protected static function validateChecksum($expect, $actual): bool {
    // Maybe be more forgiving about base-16 / base-32 / base-64
    return $expect === $actual;
  }

}
