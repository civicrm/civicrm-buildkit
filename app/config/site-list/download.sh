#!/bin/bash
mkdir "$WEB_ROOT"

cat >"$WEB_ROOT/index.php" <<EOF
<?php
require_once __DIR__ . '/site-list.settings.php';
require_once \$GLOBALS['civibuild']['SITE_CONFIG_DIR'] . '/src/site-list.php';
sitelist_main(\$GLOBALS['sitelist'], \$GLOBALS['civibuild']);
EOF
