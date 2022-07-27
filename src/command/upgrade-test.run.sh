## civicrm-upgrade-test only works with drush right now
if grep -q drupal "$CMS_ROOT/index.php" || grep -q backdrop "$CMS_ROOT/index.php" || [ -f "$CMS_ROOT/wp-config.php" ] ; then
  cvutil_makeparent "$UPGRADE_LOG_DIR"
  cvutil_mkdir "$UPGRADE_LOG_DIR"
  pushd "$PRJDIR/vendor/civicrm/upgrade-test/databases" > /dev/null
    ## Note $ARGS is list of non-option parameters. The first two were action+buildname.
    ../bin/civicrm-upgrade-test --db "$CIVI_DB_NAME" --db-args "$CIVI_DB_ARGS" --web "$CMS_ROOT" --out "$UPGRADE_LOG_DIR" --junit-xml "$UPGRADE_LOG_DIR/civicrm-upgrade-test.xml" "${ARGS[@]:2}"
  popd > /dev/null
else
  echo "Skipped. civicrm-upgrade-test currently requires Drupal 7 or Backdrop and Drush."
fi
