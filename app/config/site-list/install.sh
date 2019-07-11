#!/bin/bash

## Transition: Old builds don't have "web/" folder. New builds do.
## TODO: Simplify sometime after Dec 2019
[ -d "$WEB_ROOT/web" ] && CMS_ROOT="$WEB_ROOT/web"

amp_install

#echo "<?php" > "$CMS_ROOT/site-list.settings.php"
#echo "\$civibuild['BLDDIR'] = '$BLDDIR';" >> "$CMS_ROOT/site-list.settings.php"

cat > "$CMS_ROOT/site-list.settings.php" << EOF
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

cvutil_inject_settings "$CMS_ROOT/site-list.settings.php" "site-list.settings.d"
