if cvutil_confirm "Are you sure you want destroy \"$WEB_ROOT\"? [y/N] " n y; then
  [ -d "$WEB_ROOT" ] && rm -rf "$WEB_ROOT"
  [ -d "$PRIVATE_ROOT" ] && rm -rf "$PRIVATE_ROOT"
  [ -d "$CLONE_ROOT" ] && rm -rf "$CLONE_ROOT"
  for f in "${BLDDIR}/${SITE_NAME}.sh" "${BLDDIR}/${SITE_NAME}".*.sh ; do
[ -f "$f" ] && rm -f "$f"
  done
  amp cleanup
else
  echo "Aborted" 1>&2
  exit 1
fi