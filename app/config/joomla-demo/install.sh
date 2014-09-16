#!/bin/bash

## install.sh -- Create config files and databases; fill the databases

###############################################################################
## Create virtual-host and databases

amp_install

###############################################################################
## Setup Joomla (config files, database tables)



# pushd "$WEB_ROOT" >> /dev/null
#   CMS_DB_HOSTPORT=$(cvutil_build_hostport "$CMS_DB_HOST" "$CMS_DB_PORT")
#   php cli/install.php \
#     --db-user="$CMS_DB_USER" \
#     --db-name="$CMS_DB_NAME" \
#     --db-host="$CMS_DB_HOSTPORT" \
#     --db-pass="$CMS_DB_PASS" \
#     --admin-user="$ADMIN_USER" \
#     --admin-pass="$ADMIN_PASS" \
#     --admin-email="$ADMIN_EMAIL" \
#     --offline

#   ## Joomla requires removal of "installation" directory, which mucks up git,
#   ## so we'll push them off to the side.
#   [ -d installation ] && mv installation .installation.bak
#   [ -d .git ]         && mv .git .git.bak
# popd >> /dev/null

joomla site:create "$SITE_NAME" --www="$WEB_ROOT" --mysql="$CMS_DB_USER:$CMS_DB_PASS@$CMS_DB_HOST:$CMS_DB_PORT" --joomla="$CMS_VERSION" --dbname="$CMS_DB_NAME" --nousers

# Create Admin User
joomla user:create -b "$WEB_ROOT" --name="Demonstrators Anonymous Administrator" --user="$ADMIN_USER" --pass="$ADMIN_PASS" --email="$ADMIN_EMAIL" --group='super users'

# Create Demo User
joomla user:create -b "$WEB_ROOT" --name="Demo User" --user="$DEMO_USER" --pass="$DEMO_PASS" --email="$DEMO_EMAIL" --group=registered

###############################################################################
## Setup CiviCRM (config files, database tables)
pushd "$WEB_ROOT" >> /dev/null
  ## usage: cvutil_link <to> <from>
  function cvutil_link() {
    from="$2"
    to="$1"
    cvutil_mkdir $(dirname "$to")
    pushd $(dirname "$to") >> /dev/null
      ln -s "$from" $(basename "$to")
      # mv "$from" $(basename "$to")
    popd >> /dev/null
  }
  cvutil_link plugins/user/civicrm                   "$PRIVATE_ROOT"/src/civicrm/admin/plugins/civicrm
  cvutil_link plugins/quickicon/civicrmicon          "$PRIVATE_ROOT"/src/civicrm/admin/plugins/civicrmicon
  cvutil_link plugins/system/civicrmsys              "$PRIVATE_ROOT"/src/civicrm/admin/plugins/civicrmsys
  cvutil_link administrator/components/com_civicrm   "$PRIVATE_ROOT"/src/civicrm/admin 
  cvutil_link components/com_civicrm                 "$PRIVATE_ROOT"/src/civicrm/site

popd >> /dev/null

CIVI_DOMAIN_NAME="Demonstrators Anonymous"
CIVI_DOMAIN_EMAIL="\"Demonstrators Anonymous\" <info@example.org>"
CIVI_CORE="${WEB_ROOT}/administrator/components/com_civicrm/civicrm"
CIVI_SETTINGS="${WEB_ROOT}/components/com_civicrm/civicrm.settings.php"
CIVI_ADMSETTINGS="${WEB_ROOT}/administrator/components/com_civicrm/civicrm.settings.php"
CIVI_FILES="${WEB_ROOT}/media/civicrm"
CIVI_TEMPLATEC="${CIVI_FILES}/templates_c"
CIVI_UF="Joomla"

cat > "$CIVI_CORE/civicrm.config.php" <<EOF
<?php
define('CIVICRM_JOOMLA_BASE', '$WEB_ROOT');
define('CIVICRM_SETTINGS_PATH', '$CIVI_ADMSETTINGS');
\$error = @include_once( '$CIVI_ADMSETTINGS' );
if ( \$error == false ) {
    echo "Could not load the settings file at: $CIVI_ADMSETTINGS\n";
    exit( );
}

// Load class loader
require_once \$civicrm_root . '/CRM/Core/ClassLoader.php';
CRM_Core_ClassLoader::singleton()->register();
EOF

civicrm_install
sed "s;$CMS_URL;$CMS_URL/administrator/;g" < "$CIVI_SETTINGS" > "$CIVI_ADMSETTINGS"
## $CMS_URL/

cvutil_mkdir "$TMPDIR/$SITE_NAME"{,/joomlaxml,/joomlaxml/admin}
php "$CIVI_CORE/distmaker/utils/joomlaxml.php" "$CIVI_CORE" "$TMPDIR/$SITE_NAME/joomlaxml" "$CIVI_VERSION" alt
cp -f "$TMPDIR/$SITE_NAME/joomlaxml/civicrm.xml" "$WEB_ROOT/administrator/components/com_civicrm/civicrm.xml"
cp -f "$TMPDIR/$SITE_NAME/joomlaxml/admin/access.xml" "$WEB_ROOT/administrator/components/com_civicrm/access.xml"
#echo '<?php /* AUTO-GENERATED */ ?>' > "administrator/components/com_civicrm/script.civicrm.php"
cp -f "src/civicrm/script.civicrm.php" "administrator/components/com_civicrm/script.civicrm.php"

#Only in joomla-demo.working-from-tarball/administrator/language/en-GB: en-GB.com_civicrm.ini
#Only in joomla-demo.working-from-tarball/administrator/language/en-GB: en-GB.com_civicrm.sys.ini


# Run Joomla Discover Install
joomla extension:install "$SITE_NAME" civicrm --www="$WEB_ROOT" --mysql="$CMS_DB_USER":"$CMS_DB_PASS"@"$CMS_DB_HOSTPORT"

set +x
echo "================================================================================"
echo "================================================================================"
echo "== NOTE: The 'joomla-demo' scripts are still in development. The following    =="
echo "== features are not supported:                                                =="
echo "==   - Install CiviCRM                                                        =="
echo "==   - Create demo user                                                       =="
echo "==   - Set permissions of demo user                                           =="
echo "================================================================================"
echo "================================================================================"
set -x
