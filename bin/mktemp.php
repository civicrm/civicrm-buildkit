#!/usr/bin/env php
<?php
echo tempnam(sys_get_temp_dir(), empty($argv[1]) ? 'mktemp-' : $argv[1] );
