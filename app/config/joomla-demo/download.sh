#!/usr/bin/env bash

## download.sh -- Download Joomla and CiviCRM

###############################################################################

CMS_VERSION=${CMS_VERSION:-latest}
CMS_ROOT="$WEB_ROOT/joomla"

cvutil_mkdir "$WEB_ROOT" "$WEB_ROOT/src"

joomla site:download joomla --release="$CMS_VERSION" --www="$WEB_ROOT"

pushd "$WEB_ROOT" >> /dev/null
  git_cache_clone civicrm/civicrm-joomla            -b "$CIVI_VERSION" src/civicrm
  git_cache_clone civicrm/civicrm-core              -b "$CIVI_VERSION" src/civicrm/admin/civicrm
  git_cache_clone civicrm/civicrm-packages          -b "$CIVI_VERSION" src/civicrm/admin/civicrm/packages

  git_set_hooks civicrm-joomla      src/civicrm                      "../admin/civicrm/tools/scripts/git"
  git_set_hooks civicrm-core        src/civicrm/admin/civicrm                      "../tools/scripts/git"
  git_set_hooks civicrm-packages    src/civicrm/admin/civicrm/packages          "../../tools/scripts/git"

  ## NOTE: Evertyhing below here is generally untested; may need a mix of changes to the script and to upstream code
  pushd src/civicrm/admin > /dev/null
    #ln -s admin.civicrm.php civicrm.php
    mv admin.civicrm.php civicrm.php
  popd >> /dev/null
popd >> /dev/null

## NOTE: Evertyhing below here is generally untested; may need a mix of changes to the script and to upstream code
pushd "$WEB_ROOT/joomla" >> /dev/null
  ## usage: cvutil_link <to> <from>
  function cvutil_link() {
    from="$2"
    to="$1"
    cvutil_mkdir $(dirname "$to")
    pushd $(dirname "$to") >> /dev/null
      if test -L $(basename "$to") ; then
        rm -f $(basename "$to")
      fi
      ln -s "$from" $(basename "$to")
      # mv "$from" $(basename "$to")
      # cp -R "$from" $(basename "$to")
    popd >> /dev/null
  }

  cvutil_link plugins/user/civicrm                   "$WEB_ROOT"/src/civicrm/admin/plugins/civicrm
  cvutil_link plugins/quickicon/civicrmicon          "$WEB_ROOT"/src/civicrm/admin/plugins/civicrmicon
  cvutil_link plugins/system/civicrmsys              "$WEB_ROOT"/src/civicrm/admin/plugins/civicrmsys
  cvutil_link administrator/components/com_civicrm   "$WEB_ROOT"/src/civicrm/admin
  cvutil_link components/com_civicrm                 "$WEB_ROOT"/src/civicrm/site
popd >> /dev/null
