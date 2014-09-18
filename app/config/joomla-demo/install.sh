#!/bin/bash

## install.sh -- Create config files and databases; fill the databases

###############################################################################
## Create virtual-host and databases

amp_install

###############################################################################
## Setup Joomla (config files, database tables)

pushd "$CMS_ROOT" >> /dev/null
  joomla site:create . --download=no --install=yes \
    --joomla="$CMS_VERSION" \
    --mysql="$CMS_DB_USER:$CMS_DB_PASS@$CMS_DB_HOST:$CMS_DB_PORT" \
    --dbname="$CMS_DB_NAME" \
    --nousers
popd >>/dev/null

# Create Admin User
joomla user:create -b "$CMS_ROOT" --name="Demonstrators Anonymous Administrator" --user="$ADMIN_USER" --pass="$ADMIN_PASS" --email="$ADMIN_EMAIL" --group='super users'

# Create Demo User
joomla user:create -b "$CMS_ROOT" --name="Demo User" --user="$DEMO_USER" --pass="$DEMO_PASS" --email="$DEMO_EMAIL" --group=registered

###############################################################################
## Setup CiviCRM (config files, database tables)

CIVI_DOMAIN_NAME="Demonstrators Anonymous"
CIVI_DOMAIN_EMAIL="\"Demonstrators Anonymous\" <info@example.org>"
CIVI_CORE="${CMS_ROOT}/administrator/components/com_civicrm/civicrm"
CIVI_SETTINGS="${CMS_ROOT}/components/com_civicrm/civicrm.settings.php"
CIVI_ADMSETTINGS="${CMS_ROOT}/administrator/components/com_civicrm/civicrm.settings.php"
CIVI_FILES="${CMS_ROOT}/media/civicrm"
CIVI_TEMPLATEC="${CIVI_FILES}/templates_c"
CIVI_UF="Joomla"

cat > "$CIVI_CORE/civicrm.config.php" <<EOF
<?php
define('CIVICRM_JOOMLA_BASE', '$CMS_ROOT');
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

## NOTE: Evertyhing below here is generally untested; may need a mix of changes to the script and to upstream code
cvutil_mkdir "$TMPDIR/$SITE_NAME"{,/joomlaxml,/joomlaxml/admin}
php "$CIVI_CORE/distmaker/utils/joomlaxml.php" "$CIVI_CORE" "$TMPDIR/$SITE_NAME/joomlaxml" "$CIVI_VERSION" alt
cp -f "$TMPDIR/$SITE_NAME/joomlaxml/civicrm.xml" "$CMS_ROOT/administrator/components/com_civicrm/civicrm.xml"
cp -f "$TMPDIR/$SITE_NAME/joomlaxml/admin/access.xml" "$CMS_ROOT/administrator/components/com_civicrm/access.xml"
echo '<?php /* AUTO-GENERATED */ ?>' > "$CMS_ROOT/administrator/components/com_civicrm/script.civicrm.php"
cat "$WEB_ROOT/src/civicrm/script.civicrm.php" >> "$CMS_ROOT/administrator/components/com_civicrm/script.civicrm.php"

#Only in joomla-demo.working-from-tarball/administrator/language/en-GB: en-GB.com_civicrm.ini
#Only in joomla-demo.working-from-tarball/administrator/language/en-GB: en-GB.com_civicrm.sys.ini

# Run Joomla Discover Install
pushd "$CMS_ROOT"
#fixme  joomla extension:install . civicrm --mysql="$CMS_DB_USER":"$CMS_DB_PASS"@"$CMS_DB_HOSTPORT"
popd
