#!/usr/bin/env pogo
<?php

## Example usage:
##  1. Open "Patch Release Notes" sheet
##  2. In "Output-Markdown", copy the exported blob
##  3. Run "import-rn". Paste at the appropriate time. Press "Enter' and "Ctrl-D".

################################################################################
#!ttl 10 years
#!require clippy/std: ~0.3.5
namespace Clippy;

use Symfony\Component\Console\Style\SymfonyStyle;
use Symfony\Component\Console\Question\Question;

$c = clippy()->register(plugins());

################################################################################

$c['getCiviVersion()'] = function() {
  $xmlObj = \simplexml_load_string(file_get_contents("xml/version.xml"));
  return (string) $xmlObj->version_no;
};

$c['app']->main('', function(SymfonyStyle $io, Cmdr $cmdr, callable $getCiviVersion) {

  if (!is_dir('release-notes') || !file_exists('release-notes.md')) {
    throw new \RuntimeException("Must run in the civicrm folder");
  }

  $question = new Question('Paste base64 blob');
  $question->setMultiline(TRUE);
  $raw = $io->askQuestion($question);
  $base64 = preg_replace(';[\s"]*;', '', $raw);

  $json = base64_decode(str_replace(['-', '_'], ['+', '/'], $base64));
  $info = json_decode($json, TRUE);
  if (empty($info) || empty($info['version']) || empty($info['mdToc']) || empty($info['mdAll'])) {
    throw new \RuntimeException("Malformed input. Be sure to paste the Base64-JSON blob.");
  }

  $io->writeln("Received release notes for \"" . $info['version'] . '"');

  $currentVersion = $getCiviVersion();
  if ($getCiviVersion() === $info['version']) {
    $io->info("The current version ($currentVersion) matches the new version ({$info['version']}).");
  }
  else {
    $io->warning("The current version ($currentVersion) does not match the new version ({$info['version']})!");
    if ($io->confirm('Update version to ' . $info['version'] . '?')) {
      $cmdr->passthru('./tools/bin/scripts/set-version.php {{0|s}} --commit', [$info['version']]);
    }
  }

  $file = 'release-notes/' . $info['version'] . '.md';
  if ($io->confirm("Create \"$file\"?")) {
    file_put_contents($file, $info['mdAll']);
    $cmdr->passthru("git add {{0|s}}", [$file]);
  }

  $allLines = explode("\n", file_get_contents('release-notes.md'));
  if (preg_grep('/^#.*' . preg_quote($info['version']) . '/', $allLines)) {
    $io->warning('Already found "' . $info['version'] . '" in "release-notes.md"');
  }
  else {
    if ($io->confirm('Update "release-notes.md"?')) {
      // Find the first '## Heading'. Inject just before that.
      $offset = NULL;
      for ($i = 0; $i < count($allLines); $i++) {
        if (strpos($allLines[$i], '##') === 0) {
          $offset = $i;
          break;
        }
      }

      if ($offset === NULL) {
        throw new \RuntimeException("Failed to find injection point");
      }

      array_splice($allLines, $offset, 0, [trim($info['mdToc']) . "\n"]);

      file_put_contents('release-notes.md', implode("\n", $allLines));
      $cmdr->passthru("git add release-notes.md");
    }
  }

  if ($io->confirm('Commit changes?')) {
    $cmdr->passthru('git commit -m {{0|s}}', ["Add $file"]);
  }

});
