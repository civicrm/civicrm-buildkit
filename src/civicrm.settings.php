<?php
// TODO: Delete this file
//
// We briefly (for ~1 day) referenced "civicrm.settings.php" in new builds
// -- but then transitioned to "civibuild.settings.php".  This provides
// compatibility.

require_once './civibuild.settings.php';
function _civibuild_civicrm_settings($civibuild) {
  _civibuild_settings($civibuild['CIVI_SETTINGS'], 'civicrm.settings.d', $civibuild);
}