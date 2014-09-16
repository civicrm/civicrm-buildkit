#!/bin/bash

## download.sh -- Download Joomla and CiviCRM

###############################################################################

## TODO: Checkout Civi's code...
cvutil_mkdir "$PRIVATE_ROOT" "$PRIVATE_ROOT/src"

pushd "$PRIVATE_ROOT" >> /dev/null
	git clone ${CACHE_DIR}/civicrm/civicrm-joomla.git    -b "$CIVI_VERSION" src/civicrm
	git clone ${CACHE_DIR}/civicrm/civicrm-core.git      -b "$CIVI_VERSION" src/civicrm/admin/civicrm
	git clone ${CACHE_DIR}/civicrm/civicrm-packages.git  -b "$CIVI_VERSION" src/civicrm/admin/civicrm/packages

	git_set_hooks civicrm-joomla      src/civicrm                      "../admin/civicrm/tools/scripts/git"
	git_set_hooks civicrm-core        src/civicrm/admin/civicrm                      "../tools/scripts/git"
	git_set_hooks civicrm-packages    src/civicrm/admin/civicrm/packages          "../../tools/scripts/git"

	pushd src/civicrm/admin > /dev/null
	  #ln -s admin.civicrm.php civicrm.php
	  mv admin.civicrm.php civicrm.php
	popd >> /dev/null

popd >> /dev/null

cvutil_mkdir "$WEB_ROOT"


