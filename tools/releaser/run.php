#!/usr/bin/env php
<?php

require_once __DIR__ . "/vendor/autoload.php";
require_once file_exists(__DIR__ . "/script.php") ? __DIR__ . "/script.php" : $_ENV["POGO_SCRIPT"];
