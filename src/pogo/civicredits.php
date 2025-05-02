#!/usr/bin/env pogo
<?php
namespace Clippy;

## credits.php - Build a list of contributor names (with autocompletion, based on contributor-key.yml)

#!ttl 10 years
#!require clippy/std: ~0.5.1
#!require symfony/yaml: "~3.0|~4.0|~5.0"

use Symfony\Component\Console\Style\SymfonyStyle;
use Symfony\Component\Console\Question\Question;

$c = clippy()->register(plugins());


/**
 * @param array[] $ppl The list of contributor records
 * @param int[] $ids The list of selected contributor IDs
 * @param string[] $extras Additional contributor names that do not appear in the official listing
 * @return string[] List of names
 */
$c['fmtNames()'] = function($ppl, $ids, $extras, $input = NULL, $fmtNamesOrdered = NULL, $fmtNamesByOrg = NULL) {
  $fmt = $input->getOption('ordered') ? $fmtNamesOrdered : $fmtNamesByOrg;
  return $fmt($ppl, $ids, $extras);
};

/**
 * @param array[] $ppl The list of contributor records
 * @param int[] $ids The list of selected contributor IDs
 * @param string[] $extras Additional contributor names that do not appear in the official listing
 * @return string[] List of names
 */
$c['fmtNamesOrdered()'] = function($ppl, $ids, $extras, SymfonyStyle $io) {
  $names = [];
  foreach ($ids as $id) {
    $p = $ppl[$id];
    if (!empty($p['organization'])) {
      $names[] = sprintf("%s of %s", $p['name'] ?? $p['github'], $p['organization']);
    }
    else {
      $names[] = $p['name'] ?? $p['github'];
    }
  }
  return $names;
};

/**
 * @param array[] $ppl The list of contributor records
 * @param int[] $ids The list of selected contributor IDs
 * @param string[] $extras Additional contributor names that do not appear in the official listing
 * @return string[] List of names
 */
$c['fmtNamesByOrg()'] = function($ppl, $ids, $extras, SymfonyStyle $io) {
  $orgs = [];
  $names = [];
  foreach ($ids as $id) {
    $p = $ppl[$id];
    if (!empty($p['organization'])) {
      $orgs[$p['organization']][] = $p['name'] ?? $p['github'];
    }
    else {
      $names[] = $p['name'] ?? $p['github'];
    }
  }
  foreach ($extras as $extra) {
    $names[] = $extra;
  }
  foreach ($orgs as $orgName => $orgPpl) {
    $names[] = sprintf("%s - %s", $orgName, implode(', ', $orgPpl));
  }

  usort($names, function($a, $b) {
    return strnatcmp(mb_strtolower($a), mb_strtolower($b));
  });
  return array_reverse($names);
  // return $names;
};

/**
 * Main method: Ask for a list of names, then print them out!
 * @param string $yamlFile
 * @param callable $fmtNames
 */
$c['app']->main('[yamlFile] [--ordered]', function(SymfonyStyle $io, $yamlFile, $fmtNames) {
  $io->title(basename(__FILE__) . ": Build a list of contributor names");
  $io->section("Load contributor index");
  $yamlFile = $yamlFile ?? 'contributor-key.yml';
  $io->note("Parse $yamlFile");
  $ppl = \Symfony\Component\Yaml\Yaml::parseFile($yamlFile);
  $io->note(sprintf("Found %d contributor records", count($ppl)));
  $labels = [];
  foreach ($ppl as $id => &$person) {
    $labels[] = sprintf('%s (%s at %s) <#%d>', $person['github'] ?? '', $person['name'] ?? '', $person['organization'] ?? '', $id);
    $labels[] = sprintf('%s at %s (github %s) <#%d>', $person['name'] ?? '', $person['organization'] ?? '', $person['github'] ?? '', $id);
  }

  $io->section("Choose contributor names");
  $idFlags = [];
  $extras = [];
  do {
    $names = $fmtNames($ppl, array_keys($idFlags), $extras);
    $io->writeln(implode(";\n", $names));
    $question = new Question('Add a name (blank to finish)');
    $question->setAutocompleterValues($labels);
    $value = $io->askQuestion($question);
    if ($value && preg_match(';\<#([0-9]+)\>;', $value, $m)) {
      $idFlags[$m[1]] = 1;
    }
    elseif ($value) {
      $extras[] = $value;
    }
  } while ($value);

  $names = $fmtNames($ppl, array_keys($idFlags), $extras);
  $io->section("Final list");
  $io->writeln(wordwrap(
    implode("; ", $names),
    100
  ));
});
