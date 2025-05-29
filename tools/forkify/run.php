#!/usr/bin/env php
<?php


$_SERVER["POGO_SCRIPT"] = $_ENV["POGO_SCRIPT"] = '/Users/totten/bknix/src/pogo/forkify.php';
putenv("POGO_SCRIPT=" . $_ENV["POGO_SCRIPT"]);

$_SERVER["POGO_AUTOLOAD"] = $_ENV["POGO_AUTOLOAD"] =  __DIR__ . "/vendor/autoload.php";
putenv("POGO_AUTOLOAD=" . $_ENV["POGO_AUTOLOAD"]);

unset($_SERVER["POGO_STDIN"]);
unset($_ENV["POGO_STDIN"]);
putenv("POGO_STDIN");

require_once __DIR__ . "/vendor/autoload.php";
require_once file_exists(__DIR__ . "/script.php") ? __DIR__ . "/script.php" : $_ENV["POGO_SCRIPT"];
