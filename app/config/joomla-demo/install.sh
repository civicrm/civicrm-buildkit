#!/bin/bash

## install.sh -- Create config files and databases; fill the databases

###############################################################################
## Create virtual-host and databases

amp_install

###############################################################################
## Setup Joomla (config files, database tables)

joomla_install

pushd "$CMS_ROOT" >> /dev/null
  joomla_reset_user 'admin' "$ADMIN_USER" "$ADMIN_PASS" "$ADMIN_EMAIL"
  joomla_reset_user 'user' "$DEMO_USER" "$DEMO_PASS" "$DEMO_EMAIL"
  joomla_extension_installfile "${CACHE_DIR}/civicrm-NIGHTLY-joomla.zip"
  ## Need to override `CIVICRM_UF_BASEURL` because the default installer (when run on CLI) produces a bad configuration.
  cvutil_inject_settings "./components/com_civicrm/civicrm.settings.php" "joomla-frontend-civicrm.d"
  cvutil_inject_settings "./administrator/components/com_civicrm/civicrm.settings.php" "joomla-backend-civicrm.d"
popd >>/dev/null
