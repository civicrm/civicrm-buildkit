<?php

global $conf, $civibuild, $databases;

$conf['wmf_common_di_location'] = $civibuild['WEB_ROOT'] . "/DonationInterface";
$conf['wmf_common_phpmailer_location'] = $civibuild['WEB_ROOT'] . "/phpmailer";
$conf['wmf_common_twig_location'] = $civibuild['WEB_ROOT'] . "/twig/current";

$databases['donations']['default'] = $databases['default']['default'];
$databases['fredge']['default'] = $databases['default']['default'];
