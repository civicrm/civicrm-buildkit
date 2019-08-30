#!/bin/bash

## install.sh -- Create config files and databases; fill the databases

CMS_ROOT="$WEB_ROOT/web"

###############################################################################
## Create virtual-host and databases

amp_install

###############################################################################
cvutil_mkdir "$WEB_ROOT/out" "$WEB_ROOT/out/gen" "$WEB_ROOT/out/tmp" "$WEB_ROOT/out/tar" "$WEB_ROOT/out/config"

cat > "$WEB_ROOT/src/distmaker/distmaker.conf" <<EODIST
#!/bin/bash
[ -z "\$DM_SOURCEDIR" ]   && DM_SOURCEDIR=$WEB_ROOT/src
[ -z "\$DM_GENFILESDIR" ] && DM_GENFILESDIR=$WEB_ROOT/out/gen
[ -z "\$DM_TMPDIR" ]      && DM_TMPDIR=$WEB_ROOT/out/tmp
[ -z "\$DM_TARGETDIR" ]   && DM_TARGETDIR=$WEB_ROOT/out/tar
[ -z "\$DM_VERSION" ]     && DM_VERSION=\$( php -r '\$x=simplexml_load_file("../xml/version.xml"); echo \$x->version_no;' )
## distmaker.conf gets loaded multiple times, but we only want suffix applied once
DM_VERSION=\${DM_VERSION}\${DM_VERSION_SUFFIX}
export DM_VERSION_SUFFIX=

DM_PHP=php
DM_RSYNC=rsync
DM_ZIP=zip

# DM_VERSION= <Set this to whatever the version number should be>

## Git banch/tag name
[ -z "\$DM_REF_CORE" ] && DM_REF_CORE=$CIVI_VERSION

DM_REF_DIRNAME=\$(dirname \$DM_REF_CORE)/
if [ "\$DM_REF_DIRNAME" == "./" ]; then
  DM_REF_DIRNAME=
fi
DM_REF_BASENAME=\$(basename \$DM_REF_CORE)

DM_REF_BACKDROP=\${DM_REF_DIRNAME}1.x-\${DM_REF_BASENAME}
DM_REF_DRUPAL=\${DM_REF_DIRNAME}7.x-\${DM_REF_BASENAME}
DM_REF_DRUPAL6=\${DM_REF_DIRNAME}6.x-\${DM_REF_BASENAME}
DM_REF_DRUPAL8=\${DM_REF_DIRNAME}\${DM_REF_BASENAME}
DM_REF_JOOMLA=\${DM_REF_DIRNAME}\${DM_REF_BASENAME}
DM_REF_WORDPRESS=\${DM_REF_DIRNAME}\${DM_REF_BASENAME}
DM_REF_PACKAGES=\${DM_REF_DIRNAME}\${DM_REF_BASENAME}

EODIST

# create a minimal civicrm.settings.php file; needed for joomla's xml-generation script
cat > "$WEB_ROOT/out/config/civicrm.settings.php" << EOSETTING
<?php
define('CIVICRM_GETTEXT_RESOURCEDIR', '$WEB_ROOT/src/l10n/');
define('CIVICRM_UF', 'Drupal');
global \$civicrm_root;
\$civicrm_root = '$WEB_ROOT/src';
?>
EOSETTING
echo "<?php define('CIVICRM_CONFDIR', '$WEB_ROOT/out/config'); ?>" > "$WEB_ROOT/src/settings_location.php"
