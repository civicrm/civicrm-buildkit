cvutil_assertvars serve WEB_ROOT

#PHP_SERVE=$( echo "$CMS_URL" | cut -f3 -d/ )
#pushd "$CMS_ROOT"
#  echo  php -S "$PHP_SERVE" -t "$CMS_ROOT" "$CIVI_CORE/tools/standalone/router.php"
#  php -S "$PHP_SERVE" -t "$CMS_ROOT" "$CIVI_CORE/tools/standalone/router.php"
#popd

pushd "$WEB_ROOT" > /dev/null
  civibuild_app_run serve
popd > /dev/null

