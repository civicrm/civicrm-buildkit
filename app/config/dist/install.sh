#!/bin/bash

## install.sh -- Create config files and databases; fill the databases

###############################################################################
## Create virtual-host and databases

amp_install

###############################################################################
cvutil_mkdir "$WEB_ROOT/distmaker/out" "$WEB_ROOT/distmaker/out/gen" "$WEB_ROOT/distmaker/out/tmp" "$WEB_ROOT/distmaker/out/tar"

cat > "$WEB_ROOT/distmaker/distmaker.conf" <<EODIST
#!/bin/bash
DM_SOURCEDIR=$WEB_ROOT
DM_GENFILESDIR=$WEB_ROOT/distmaker/out/gen
DM_TMPDIR=$WEB_ROOT/distmaker/out/tmp
DM_TARGETDIR=$WEB_ROOT/distmaker/out/tar
  
DM_PHP=php
DM_RSYNC=rsync
DM_ZIP=zip

# DM_VERSION= <Set this to whatever the version number should be>
if [ -z "\$DM_VERSION" ]; then
  echo "=========================================================="
  echo "ERROR: Please set DM_VERSION to the desired output version"
  exit 2
fi

## Git banch/tag name
DM_REF_CORE=${CIVI_VERSION}
DM_REF_DRUPAL=7.x-\${DM_REF_CORE}
DM_REF_DRUPAL6=6.x-\${DM_REF_CORE}
DM_REF_JOOMLA=\${DM_REF_CORE}
DM_REF_WORDPRESS=\${DM_REF_CORE}
DM_REF_PACKAGES=\${DM_REF_CORE}
EODIST

