#!/usr/bin/env pogo
<?php
namespace Clippy;

## About: Recursively compare the contents of two archives or directories.
##
## Usage: zipdiff [-s|--strict] [--name-only] <oldArchivePath> <newArchivePath> [filterFiles...]
##
## Ex: zipdiff -b org.example.civixsnapshot-v16.02.0-empty.zip org.example.civixsnapshot-v16.02.0-qf.zip
## Ex: zipdiff -b org.example.civixsnapshot-v16.02.0-empty.zip org.example.civixsnapshot-v16.02.0-qf.zip info.xml
## Ex: zipdiff -b org.example.civixsnapshot-v16.02.0-empty.zip $CIVIBUILD_HOME/dmaster/web/sites/all/modules/civicrm/ext/civixtest
##
## By default, filenames are trimmed for readibility. For example:
##
## - BASEDIR: Often, an archive includes a basedir shared by all files. This can be tricky to diff, especially when the
##   basedir has version#s or timestamps. This will be disregarded by default. (It will be examined in `--strict` mode.)
## - ABBREVIATE: In `git diff`, the repo is given an abstract abbreviation -- with "a/" and "/b" standing in for the old
##   and new sources. Similarly, `zipdiff` shows paths relative to "a/" and "b/" by default. (But in `--strict` mode,
##   it will show the full base.)

###########################################
## Imports

#!ttl 10 years

#!require sebastian/diff: ~4.0.4
use SebastianBergmann\Diff\Differ;
use SebastianBergmann\Diff\Output\StrictUnifiedDiffOutputBuilder;

#!require wapmorgan/unified-archive: ~1.1.8
use wapmorgan\UnifiedArchive\UnifiedArchive;

#!require clippy/std: ~0.3.5
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;

###########################################
## Printer - How to display diffs

abstract class Printer {
  abstract public function showAdded($name, $content);
  abstract public function showRemoved($name, $content);
  abstract public function showUnchanged($name, $content);
  abstract public function showChanged($name, $oldContent, $newContent);
}

class NameOnlyPrinter extends Printer {
  public function showAdded($name, $newContent) { echo "$name\n"; }
  public function showRemoved($name, $oldContent) { echo "$name\n"; }
  public function showUnchanged($name, $content) {}
  public function showChanged($name, $oldContent, $newContent) { echo "$name\n"; }
}

class UnifiedDiffPrinter extends Printer {
  protected $oldBase;
  protected $newBase;
  protected $delim;

  public function __construct(string $oldBase, string $newBase, string $delim = '/') {
    $this->oldBase = $oldBase;
    $this->newBase = $newBase;
    $this->delim = $delim;
  }

  public function showAdded($relPath, $newContent) {
    $path = "{$this->newBase}{$this->delim}{$relPath}";
    printf("Only in %s: %s\n", dirname($path), basename($path));
  }
  public function showRemoved($name, $oldContent) {
    $path = "{$this->oldase}{$this->delim}{$relPath}";
    printf("Only in %s: %s\n", dirname($path), basename($path));
  }
  public function showUnchanged($name, $content) {}
  public function showChanged($name, $oldContent, $newContent) {
    echo "diff -ru --zip {$this->oldBase}{$this->delim}{$name} {$this->newBase}{$this->delim}{$name}\n";
    $builder = new StrictUnifiedDiffOutputBuilder([
      'fromFile' => "{$this->oldBase}{$this->delim}{$name}",
      // 'fromFileDate' => date('Y-m-d H:i:s O'),
      'toFile' => "{$this->newBase}{$this->delim}{$name}",
      // 'toFileDate' => date('Y-m-d H:i:s O'),
    ]);
    echo (new Differ($builder))->diff($oldContent, $newContent);
  }
}

###########################################
## Archive Readers

abstract class Archive {
  protected $path;

  public function __construct(string $path) {
    $this->path = trimFileName($path);
  }

  public function getArchivePath(): string {
    return $this->path;
  }

  abstract public function getFiles(): array;
  abstract public function hasFile(string $file): bool;
  abstract public function getFileContent(string $file): string;
}

class DirectoryArchive extends Archive {
  public function getFiles(): array {
    $dir = new \RecursiveDirectoryIterator($this->path, \RecursiveDirectoryIterator::SKIP_DOTS);
    $files = new \RecursiveIteratorIterator($dir, \RecursiveIteratorIterator::CHILD_FIRST);
    $result = [];
    foreach ($files as $file) {
      if (!$file->isDir()) {
        $relPath = substr($file->getPathname(), 1 + strlen($path));
        $result[] = str_replace(DIRECTORY_SEPARATOR, '/', $relPath);
      }
    }
    return $result;
  }

  public function hasFile(string $file): bool {
    return file_exists($this->path . DIRECTORY_SEPARATOR . $file);
  }

  public function getFileContent(string $file): string {
    return file_get_contents($this->path . DIRECTORY_SEPARATOR . $file);
  }
}

class AutoArchive extends Archive {
  protected $archive;
  protected $prefix;

  public function __construct(string $path, bool $hidePrefix) {
    parent::__construct($path);
    // We will delegate to the "UnifiedArchive" because it supports many formats. But we may need to filter it.
    $this->archive = UnifiedArchive::open($path);
    $this->prefix = $hidePrefix ? $this->findCommonPrefix() : '';
  }

  public function getFiles(): array {
    return $this->filterByPrefix($this->prefix, $this->archive->getFiles());
  }

  public function hasFile(string $file): bool {
    return $this->archive->hasFile($this->prefix . $file);
  }

  public function getFileContent(string $file): string {
    return $this->archive->getFileContent($this->prefix . $file);
  }

  protected function findCommonPrefix(): string {
    $all = trimFileName($this->archive->getFiles());
    if (empty($all)) return '';

    $first = array_shift($all);
    if (FALSE === mb_strpos($first, '/')) return '';
    [$prefix] = explode('/', $first);
    $prefix .= '/';

    // Is this prefix shared by all?
    return count($all) === count($this->filterByPrefix($prefix, $all)) ? $prefix : '';
  }

  protected static function filterByPrefix(string $prefix, array $all): array {
    if ($prefix === '') return $all;
    $pat = ';^' . preg_quote($prefix, ';') . '(.*)$;';
    $result = [];
    foreach ($all as $item) {
      if (preg_match($pat, $item, $m)) {
        $result[] = $m[1];
      }
    }
    return $result;
  }
}

function trimFileName($stringOrArray) {
  if (is_array($stringOrArray)) {
    return array_map(__FUNCTION__, $stringOrArray);
  }
  else {
    return rtrim($stringOrArray, '/' . DIRECTORY_SEPARATOR);
  }
}

###########################################
## Main

$c = clippy()->register(plugins());

$c['oldArchive'] = function (InputInterface $input) {
  $path = $input->getArgument('oldArchivePath');
  return is_dir($path) ? new DirectoryArchive($path) : new AutoArchive($path, !$input->getOption('strict'));
};

$c['newArchive'] = function (InputInterface $input) {
  $path = $input->getArgument('newArchivePath');
  return is_dir($path) ? new DirectoryArchive($path) : new AutoArchive($path, !$input->getOption('strict'));
};

$c['printer'] = function (Archive $oldArchive, Archive $newArchive, InputInterface $input) {
  if ($input->getOption('name-only')) {
    return new NameOnlyPrinter();
  }
  elseif ($input->getOption('strict')) {
    return new UnifiedDiffPrinter($oldArchive->getArchivePath(), $newArchive->getArchivePath());
  }
  else {
    return new UnifiedDiffPrinter('a', 'b');
  }
};

$c['filterFilesRegex'] = function (InputInterface $input) {
  // The user may optionally focus on specific files within the archive.
  // If they give a file-filter, then we'll translate it to regex.

  $filterFiles = trimFileName($input->getArgument('filterFiles'));
  if (empty($filterFiles)) {
    return ';.;';
  }

  $patterns = array_map(function($filterFile) {
    $wildcard = preg_quote('*', ';');
    $pat = preg_quote($filterFile, ';');
    $pat = str_replace($wildcard . $wildcard, '.*', $pat); // Goal: 'CRM/**.php' ==> 'CRM/.*\.php'
    $pat = str_replace($wildcard, '[^/]*', $pat); // Goal: 'CRM/*.php'  ==> 'CRM/[^/]*\.php'
    return $pat;
  }, $filterFiles);
  return ';^(' . implode('|', $patterns) . ')(/.*)?$;';
};

$c['app']->main('[-s|--strict] [--name-only] oldArchivePath newArchivePath [filterFiles]*', function(Archive $oldArchive, Archive $newArchive, Printer $printer, string $filterFilesRegex) {
  $allFiles = array_unique(array_merge($oldArchive->getFiles(), $newArchive->getFiles()));
  $matchFiles = preg_grep($filterFilesRegex, $allFiles);
  sort($matchFiles);

  foreach ($matchFiles as $file) {
    if ($oldArchive->hasFile($file) && $newArchive->hasFile($file)) {
      $oldContent = $oldArchive->getFileContent($file);
      $newContent = $newArchive->getFileContent($file);
      if ($oldContent === $newContent) {
        $printer->showUnchanged($file, $oldContent);
      }
      else {
        $printer->showChanged($file, $oldContent, $newContent);
      }
    }
    elseif ($newArchive->hasFile($file)) {
      $printer->showAdded($file, $newArchive->getFileContent($file));
    }
    elseif ($oldArchive->hasFile($file)) {
      $printer->showRemoved($file, $oldArchive->getFileContent($file));
    }
  }
});
