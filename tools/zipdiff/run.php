#!/usr/bin/env php
<?php


$_SERVER["POGO_AUTOLOAD"] = $_ENV["POGO_AUTOLOAD"] =  __DIR__ . "/vendor/autoload.php";
putenv("POGO_AUTOLOAD=" . $_ENV["POGO_AUTOLOAD"]);

require_once __DIR__ . "/vendor/autoload.php";
require_once __DIR__ . "/script.php";
