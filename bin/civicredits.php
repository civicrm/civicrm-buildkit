#!/usr/bin/env pogo
<?php
namespace Clippy;

## credits.php - Build a list of contributor names (with autocompletion, based on contributor-key.yml)

#!require clippy/std: ~0.2.2
#!require symfony/yaml: ~3.0

use Symfony\Component\Console\Style\SymfonyStyle;
use Symfony\Component\Console\Question\Question;

$c = clippy()->register(plugins());
/**
 * @param array[] $ppl The list of contributor records
 * @param int[] $ids The list of selected contributor IDs
 * @param string[] $extras Additional contributor names that do not appear in the official listing
 * @return string[] List of names
 */
$c['fmtNames()'] = function($ppl, $ids, $extras, SymfonyStyle $io) {
  $orgs = [];
  $names = [];
  foreach ($ids as $id) {
    $p = $ppl[$id];
    if (!empty($p['organization'])) {
      $orgs[$p['organization']][] = $p['name'];
    }
    else {
      $names[] = $p['name'];
    }
  }
  foreach ($extras as $extra) {
    $names[] = $extra;
  }
  foreach ($orgs as $orgName => $orgPpl) {
    $names[] = sprintf("%s - %s", $orgName, implode(', ', $orgPpl));
  }

  usort($names, function($a,$b) {
    return strnatcmp(mb_strtolower($a), mb_strtolower($b));
  });
  return $names;
};

/**
 * Main method: Ask for a list of names, then print them out!
 * @param string $yamlFile
 * @param callable $fmtNames
 */
$c['app']->main('[yamlFile]', function(SymfonyStyle $io, $yamlFile, $fmtNames) {
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
    if (preg_match(';\<#([0-9]+)\>;', $value, $m)) {
      $idFlags[$m[1]] = 1;
    }
    elseif ($value) {
      $extras[] = $value;
    }
  } while ($value);

  $names = $fmtNames($ppl, array_keys($idFlags), $extras);
  $io->section("Final list");
  $io->writeln(wordwrap(
    implode("; ", array_reverse($names)),
    100
  ));
});
