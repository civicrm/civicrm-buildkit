#!/bin/bash

amp_install

#echo "<?php" > "$WEB_ROOT/site-list.settings.php"
#echo "\$civibuild['BLDDIR'] = '$BLDDIR';" >> "$WEB_ROOT/site-list.settings.php"

cat > "$WEB_ROOT/site-list.settings.php" << EOF
<?php
\$civibuild['BLDDIR'] = '$BLDDIR';

// Choose what details to display. A few examples:
global \$sitelist;
//\$sitelist['display'] =  ['ALL'];
//\$sitelist['display'] =  ['ADMIN_USER', 'DEMO_USER', 'WEB_ROOT', 'CIVI_CORE', 'CMS_DB', 'CIVI_DB', 'TEST_DB', 'SITE_TYPE', 'BUILD_TIME'];
\$sitelist['display'] = ['ADMIN_USER', 'DEMO_USER', 'SITE_TYPE', 'BUILD_TIME'];

//\$sitelist['title'] = 'My local sites';

//\$sitelist['about'] = 'These test sites are produced by the continuous-integration system.';
//\$sitelist['about'] = 'These are local development sites.';
EOF

cvutil_inject_settings "$WEB_ROOT/site-list.settings.php" "site-list.settings.d"
