cvutil_assertvars civibuild_app_edit BLDDIR SITE_NAME SITE_ID

if [ -f "${BLDDIR}/${SITE_NAME}.sh" ]; then
  echo "[[Edit ${BLDDIR}/${SITE_NAME}.sh]]"
  c="${BLDDIR}/${SITE_NAME}.sh"
fi
if [ -f "${BLDDIR}/${SITE_NAME}.${SITE_ID}.sh" ]; then
  echo "[[Edit ${BLDDIR}/${SITE_NAME}.${SITE_ID}.sh]]"
  c="${BLDDIR}/${SITE_NAME}.${SITE_ID}.sh"
fi

if [ -n "$EDITOR" ]; then
  $EDITOR $c
else
  echo "No editor found - please configure your EDITOR env variable."
fi
