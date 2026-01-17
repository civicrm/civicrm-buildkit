<?php

/**
 * @file
 *
 * Browse the list of assets on a Gitlab project.
 *
 * gitlab-release ls <REPO_URL> [<FILE_PATTERN>]
 * gitlab-release ls https://gitlab.com/foo/bar/ \*.tar.gz
 */

define('TTL', 3 * 60 * 60);
// define('TTL', 15 * 60);

/**
 * In theory, a project might have symbolic tags that don't look like version-numbers.
 * Ignore these.
 */
define('STANDARD_TAG_FILTER', ';^v?[0-9]+;');

/**
 * Get a list of publicly released assets for a Gitlab project.
 *
 * @param string $repoUrl
 * @return array|void
 */
function get_all_releases(string $repoUrl) {
  $cacheDir = getenv('XDG_CACHE_HOME') ?: (getenv('HOME') . '/.cache');
  $cachePath = $cacheDir . '/gitlab-release/' . md5($repoUrl) . '.json';
  $cacheTtl = TTL;

  if (file_exists($cachePath) && (time() - filemtime($cachePath) < $cacheTtl)) {
    return json_decode(file_get_contents($cachePath), TRUE);
  }

  $releases = [];

  $urlParts = parse_url($repoUrl);
  $path = ltrim($urlParts['path'], '/');
  $apiBase = "https://" . ($urlParts['host'] ?? 'gitlab.com') . "/api/v4/projects/" . urlencode($path) . "/releases";

  $nextUrl = $apiBase . "?per_page=100";

  while ($nextUrl) {
    $options = ['http' => ['method' => "GET", 'header' => "User-Agent: PHP-CLI-Script\r\n"]];
    $context = stream_context_create($options);
    $response = @file_get_contents($nextUrl, FALSE, $context);

    if ($response === FALSE) {
      echo "Error: Could not fetch releases.\n";
      exit(1);
    }

    $releases = array_merge($releases, json_decode($response, TRUE));

    $nextUrl = NULL;
    foreach ($http_response_header as $header) {
      if (stripos($header, 'Link:') === 0 && preg_match('/<([^>]+)>; rel="next"/', $header, $matches)) {
        $nextUrl = $matches[1];
        break;
      }
    }
  }

  // Save to Cache
  if (!is_dir(dirname($cachePath))) {
    mkdir(dirname($cachePath), 0755, TRUE);
  }
  file_put_contents($cachePath, json_encode($releases));

  return $releases;
}

function normalize_assets(array $releases): array {
  $rows = [];
  foreach ($releases as $release) {
    if (!preg_match(STANDARD_TAG_FILTER, $release['tag_name'])) {
      continue;
    }

    foreach ($release['assets']['links'] ?? [] as $link) {
      $rows[] = [
        'tag' => $release['tag_name'],
        'released_at' => $release['released_at'],
        'type' => 'asset',
        'name' => $link['name'],
        'url' => $link['direct_asset_url'] ?? $link['url'],
      ];
    }

    foreach ($release['assets']['sources'] ?? [] as $source) {
      $rows[] = [
        'tag' => $release['tag_name'],
        'released_at' => $release['released_at'],
        'type' => 'source',
        'name' => basename($source['url']),
        'url' => $source['url'],
      ];
    }
  }

  usort($rows, function ($a, $b) {
    if ($diff = version_compare($a['tag'], $b['tag'])) {
      return -1 * $diff;
    }
    if ($diff = strcmp($a['name'], $b['name'])) {
      return $diff;
    }
    return 0;
  });
  return $rows;
}

if ($argc < 3 || $argv[1] !== 'ls') {
  echo "Usage: gitlab-release ls <REPO_URL> [<FILE_PATTERN>]\n";
  exit(1);
}

$repoUrl = rtrim($argv[2], '/');
$pattern = $argv[3] ?? '*';
$releases = get_all_releases($repoUrl);
$assets = normalize_assets($releases);
$matches = array_filter($assets, fn($asset) => fnmatch($pattern, $asset['name']));
// print_r($matches);
foreach ($matches as $match) {
  printf("%s\n", $match['url']);
}
