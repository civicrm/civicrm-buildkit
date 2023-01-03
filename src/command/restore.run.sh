amp_snapshot_restore
if [ -n "$FORCE_INSTALL" ]; then
  (cd "$CMS_ROOT" && cv flush)
fi
cvutil_save "${BLDDIR}/${SITE_NAME}.sh" $PERSISTENT_VARS
