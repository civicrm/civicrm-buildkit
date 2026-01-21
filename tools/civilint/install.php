<?php

namespace Civi\Buildkit\Tools\Civilint;

if (empty($binDir) || !is_dir($binDir)) {
  throw new \RuntimeExcpetion("install.php: Expected valid binDir");
}
if (empty($toolDir) || !is_dir($toolDir)) {
  throw new \RuntimeExcpetion("install.php: Expected valid toolDir");
}

function renderStub(string $tool, string $toolDir): string {
  $escapedDir = escapeshellarg(rtrim($toolDir, '/'));
  return <<<FILE
#!/usr/bin/env bash
export PATH={$escapedDir}/bin:"\$PATH"
exec $tool "\$@"
FILE;
}

function createStub(string $file, string $content): void {
  printf("Create %s\n", $file);
  if (!is_dir(dirname($file))) {
    mkdir(dirname($file), 0777, TRUE);
  }
  file_put_contents($file, $content);
  chmod($file, 0755);
}

createStub("$binDir/civilint", renderStub('civilint', $toolDir));
createStub("$binDir/phpcs-civi", renderStub('phpcs-civi', $toolDir));
createStub("$binDir/phpcbf-civi", renderStub('phpcbf-civi', $toolDir));
