#!/usr/bin/env bash
mkdir "$WEB_ROOT" "$WEB_ROOT/web"

cat >"$WEB_ROOT/web/index.php" <<EOF
<?php
require_once __DIR__ . '/site-list.settings.php';
require_once \$GLOBALS['civibuild']['SITE_CONFIG_DIR'] . '/src/site-list.php';
sitelist_main(\$GLOBALS['sitelist'], \$GLOBALS['civibuild']);
EOF

mkdir "$WEB_ROOT/web/lib"
pushd "$WEB_ROOT/web/lib" >> /dev/null
  http_download "https://unpkg.com/jquery@3.5/dist/jquery.min.js" jquery.min.js
  http_download "https://unpkg.com/moment@2.29/moment.js" moment.js

  extract-url bootstrap.tmp="https://github.com/twbs/bootstrap/archive/v3.4.1.zip"
  mv bootstrap.tmp/bootstrap-3.4.1 bootstrap
  rmdir bootstrap.tmp
popd >> /dev/null
