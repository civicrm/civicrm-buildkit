<?php
namespace Loco;

function getMysqlMajorMinorCode(): ?string {
    $output = null;
    $returnVar = 0;
    @exec('mysql --version', $output, $returnVar);

    if ($returnVar !== 0 || empty($output)) {
        return null; // command failed or no output
    }

    $versionString = $output[0];

    // Check if it's MariaDB
    if (stripos($versionString, 'MariaDB') !== false) {
        if (preg_match('/Distrib\s+(\d+)\.(\d+)\.\d+-MariaDB/', $versionString, $matches)) {
            return 'mariadb' . $matches[1] . $matches[2];
        }
    }

    // Otherwise, assume MySQL
    // MySQL 5.7 format: "Distrib 5.7.37"
    if (preg_match('/Distrib\s+(\d+)\.(\d+)\./', $versionString, $matches)) {
        return 'mysql' . $matches[1] . $matches[2];
    }

    // MySQL 8.0 format: "Ver 8.0.29"
    if (preg_match('/Ver\s+(\d+)\.(\d+)\./', $versionString, $matches)) {
        return 'mysql' . $matches[1] . $matches[2];
    }

    return null; // Couldn't parse version
}

Loco::dispatcher()->addListener('loco.expr.functions', function (LocoEvent $e) {

  $e['functions']['mysql-id'] = function () {
    return getMysqlMajorMinorCode();
//    return '';
  };

});
