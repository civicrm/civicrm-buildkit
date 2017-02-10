<?php

global
    $wgDonationInterfaceEnableQueue,
    $wgDonationInterfaceOrphanCron,
    $wgDonationInterfaceGatewayAdapters,
    $wgDonationInterfaceForbiddenCountries,
    $wgDonationInterface3DSRules,
    $wgGlobalCollectGatewayEnabled,
    $wgGlobalCollectOrphanGatewayEnabled,
    $wgGlobalCollectGatewayAccountInfo,
    $wgGlobalCollectGatewayURL,
    $wgDonationInterfacePriceFloor,
    $wgDonationInterfacePriceCeiling,
    $wgDonationInterfaceRetryLoopCount,
    $wgDonationInterfaceEnableMinfraud,
    $wgDonationInterfaceEnableReferrerFilter,
    $wgDonationInterfaceEnableSourceFilter,
    $wgDonationInterfaceEnableFunctionsFilter,
    $wgDonationInterfaceEnableIPVelocityFilter,
    $wgDonationInterfaceEnableSessionVelocityFilter,
    $wgGlobalCollectGatewayCustomFiltersFunctions;

$wgDonationInterfaceEnableQueue = false;

#Orphan Rectifying vars
$wgDonationInterfaceOrphanCron = array(
    'target_execute_time' => 300,
    // 20 minutes, the default.
    'time_buffer' => 1200,
);

$wgDonationInterfaceGatewayAdapters = array(
    'globalcollect' => 'GlobalCollectAdapter',
    'globalcollect_orphan' => 'GlobalCollectOrphanAdapter',
);

$wgDonationInterfaceForbiddenCountries = array(
    'KP', // For testing
);

$wgDonationInterface3DSRules = array();

$wgGlobalCollectGatewayEnabled = true;
$wgGlobalCollectOrphanGatewayEnabled = true;

# Ingenico (GlobalCollect)
$wgGlobalCollectGatewayAccountInfo['test'] = array(
    'MerchantID' => '1234',
);

$wgGlobalCollectGatewayURL = 'https://ps.gcsip.nl/wdl/wdl';

$wgDonationInterfacePriceFloor = 1;

$wgDonationInterfacePriceCeiling = 10000;

$wgDonationInterfaceRetryLoopCount = 3;

// Fraud configuration
$wgDonationInterfaceEnableMinfraud = false;
$wgDonationInterfaceEnableReferrerFilter = true;
$wgDonationInterfaceEnableSourceFilter = true;
$wgDonationInterfaceEnableFunctionsFilter = true;
// Not used for offline charges.
$wgDonationInterfaceEnableIPVelocityFilter = false;
$wgDonationInterfaceEnableSessionVelocityFilter = false;

$wgGlobalCollectGatewayCustomFiltersFunctions = array(
    'getCVVResult' => 1,
    'getAVSResult' => 3,
    'getScoreCountryMap' => 5,
    'getScoreUtmCampaignMap' => 7,
    'getScoreEmailDomainMap' => 11,
);
