#!/bin/bash
mkdir "$WEB_ROOT" "$WEB_ROOT/web"

cat >"$WEB_ROOT/web/index.php" <<EOF
<?php
require_once __DIR__ . '/site-list.settings.php';
require_once \$GLOBALS['civibuild']['SITE_CONFIG_DIR'] . '/src/site-list.php';
sitelist_main(\$GLOBALS['sitelist'], \$GLOBALS['civibuild']);
EOF
