#!/usr/bin/env php
<?php

$prjDir = dirname(__DIR__, 2);
$tmpDir = empty(getenv('CIVIBUILD_HOME')) ? ("$prjDir/app/tmp") : (getenv('CIVIBUILD_HOME') . '/.civibuild/tmp');
$_ENV['RELEASE_TMPDIR'] = "$tmpDir/releaser";
putenv("RELEASE_TMPDIR=" . $_ENV['RELEASE_TMPDIR']);
if (!is_dir($_ENV['RELEASE_TMPDIR'])) {
  mkdir($_ENV['RELEASE_TMPDIR'], 0777, TRUE);
}

require_once __DIR__ . "/vendor/autoload.php";
require_once file_exists(__DIR__ . "/script.php") ? __DIR__ . "/script.php" : $_ENV["POGO_SCRIPT"];
