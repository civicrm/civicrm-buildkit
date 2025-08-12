#!/usr/bin/env bash
cvutil_assertvars standalone_serve CMS_ROOT CIVI_CORE CMS_URL

export PHP_CLI_SERVER_WORKERS=5
PHP_SERVE=$( echo "$CMS_URL" | cut -f3 -d/ )

pushd "$CMS_ROOT"
  php -S "$PHP_SERVE" -t "$CMS_ROOT" "$CIVI_CORE/tools/standalone/router.php"
popd
