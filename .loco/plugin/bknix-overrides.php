<?php
/**
 * The bknix-overrides plugin allows you to override environment variables by creating a file '/etc/bknix-ci/loco-overrides.yaml'.
 *
 * This file has a structure which parallels the `loco.yml`, but it only supports `environment:` and `default_environment:` clauses. Example:
 *
 * ```yaml
 * ## Override system-level variables
 * default_environment:
 *   - FOO=123
 * environment:
 *   - BAR=456
 *
 * ## Override service-level variables
 * services:
 *   some-service:
 *     environment:
 *       - FOO=321
 *     default_environment:
 *       - BAR=654
 * ```
 */
namespace BknixOverrides;

use Loco\Loco;
use Symfony\Component\Yaml\Yaml;

/**
 * @param array $origAssgns
 *   Ex: ['FOO=100', 'BAR=200']
 * @param array $newAssgns
 *   Ex: ['FOO=101']
 * @return array
 *   Ex: ['FOO=101', 'BAR=200']
 */
function mergeAssignments($origAssgns, $newAssgns) {
  $output = $origAssgns;
  foreach ($newAssgns as $newAssgn) {
    list($key, $value) = explode('=', $newAssgn);
    $output = preg_grep(";^{$key}=;", $output, PREG_GREP_INVERT);
    $output[] = $newAssgn;
  }
  return $output;
}

/**
 * @param array $config
 *   The service or system config
 * @param array $override
 *   The amendments to the service or system config
 */
function applyOverrides(&$config, &$override) {
  if (isset($override['environment'])) {
    $config['environment'] = mergeAssignments($config['environment'] ?? [], $override['environment'] ?? []);
  }
  if (isset($override['default_environment'])) {
    $config['default_environment'] = mergeAssignments($config['default_environment'] ?? [], $override['default_environment'] ?? []);
  }
}

Loco::dispatcher()->addListener('loco.config.filter', function($e) {
  $f = '/etc/bknix-ci/loco-overrides.yaml';
  if (file_exists($f)) {
    $o = Yaml::parse(file_get_contents($f));
    applyOverrides($e['config'], $o);
    $svcNames = array_intersect(array_keys($e['config']['services'] ?? []), array_keys($o['services'] ?? []));
    foreach ($svcNames as $svcName) {
      applyOverrides($e['config']['services'][$svcName], $o['services'][$svcName]);
    }
  }
});
