#!/usr/bin/env php
<?php
## usage: "mktemp.php [prefix [basedir]]"
$prefix = empty($argv[1]) ? 'mktemp-' : $argv[1];
$basedir = empty($argv[2]) ? sys_get_temp_dir() : $argv[2];
echo tempnam($basedir,  $prefix);
