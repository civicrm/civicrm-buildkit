<?php

# This is an example configuration for `site-list` service on a demo server.
# It is used to initialize /etc/site-list.settings.d/post.d/demo.php.

global $civibuild, $sitelist;

# $civibuild['SITE_TOKEN'] = 'MY-sEcReT';
$sitelist['bldDirs'] = glob(getenv('HOME') . '/bknix*/build');
$sitelist['moreSites'] = [
#  'http://site-list.remote.example.com' => 'THeIr-sEcReT',
];

$sitelist['display'] = ['ADMIN_USER', 'DEMO_USER', 'SITE_TYPE', 'WEB_ROOT', 'BUILD_TIME'];
