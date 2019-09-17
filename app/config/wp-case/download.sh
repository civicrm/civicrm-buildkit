#!/bin/bash

## download.sh -- Download WordPress and CiviCRM

###############################################################################

git_cache_setup "https://github.com/civicrm/org.civicrm.shoreditch.git" "$CACHE_DIR/civicrm/org.civicrm.shoreditch.git"
git_cache_setup "https://github.com/civicrm/org.civicrm.styleguide.git" "$CACHE_DIR/civicrm/org.civicrm.styleguide.git"
git_cache_setup "https://github.com/civicrm/org.civicrm.civicase.git" "$CACHE_DIR/civicrm/org.civicrm.civicase.git"

###############################################################################

WPCLI_ARGS=
[ -n "$CMS_VERSION" ] && WPCLI_ARGS="$WPCLI_ARGS --version=$CMS_VERSION"

echo "[[Download WordPress]]"
mkdir "$WEB_ROOT"
pushd "$WEB_ROOT" >> /dev/null
  "$PRJDIR/bin/wp" core download$WPCLI_ARGS
  if [ ! -e "wp-cli.yml" ]; then
    ln -s "$SITE_CONFIG_DIR/wp-cli.yml" "wp-cli.yml"
  fi
popd >> /dev/null

echo "[[Download CiviCRM]]"
[ ! -d "$WEB_ROOT/wp-content/plugins" ] && mkdir -p "$WEB_ROOT/wp-content/plugins"
pushd $WEB_ROOT/wp-content/plugins >> /dev/null

  git clone ${CACHE_DIR}/civicrm/civicrm-wordpress.git                -b "$CIVI_VERSION" civicrm
  git clone ${CACHE_DIR}/civicrm/civicrm-core.git                     -b "$CIVI_VERSION" civicrm/civicrm
  git clone ${CACHE_DIR}/civicrm/civicrm-packages.git                 -b "$CIVI_VERSION" civicrm/civicrm/packages
  case "$CIVI_VERSION" in
   5.17|5.18)
     git clone "${CACHE_DIR}/civicrm/api4.git"                                -b "4.5.2"             civicrm/ext/api4
     ;;
   *)
     EXTCIVIVER=$( php -r '$x=simplexml_load_file("civicrm/xml/version.xml"); echo $x->version_no;' )
     cv dl -b "@https://civicrm.org/extdir/ver=$EXTCIVIVER|cms=Drupal|status=|ready=/org.civicrm.api4.xml" --to="$WEB_ROOT/web/wp-content/plugins/civicrm/civicrm/ext/api4" --dev
  esac
  git clone ${CACHE_DIR}/civicrm/api4.git                             -b "master"        civicrm/civicrm/ext/api4
  git clone ${CACHE_DIR}/civicrm/civicrm-demo-wp.git                  -b master          civicrm-demo-wp

  mkdir -p civicrm/civicrm/ext
  git clone ${CACHE_DIR}/civicrm/org.civicrm.shoreditch.git           -b master civicrm/civicrm/ext/shoreditch
  git clone ${CACHE_DIR}/civicrm/org.civicrm.styleguide.git           -b master civicrm/civicrm/ext/styleguide
  git clone ${CACHE_DIR}/civicrm/org.civicrm.civicase.git             -b master civicrm/civicrm/ext/civicase

  git_set_hooks civicrm-wordpress   civicrm                    "../civicrm/tools/scripts/git"
  git_set_hooks civicrm-core        civicrm/civicrm            "../tools/scripts/git"
  git_set_hooks civicrm-packages    civicrm/civicrm/packages   "../../tools/scripts/git"

popd >> /dev/null
