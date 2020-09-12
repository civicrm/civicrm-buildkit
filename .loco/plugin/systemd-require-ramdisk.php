<?php
namespace SystemdRequireRamdisk;
use Loco\Loco;

// If we've used `install-ci.sh` or similar, then there's a ramdisk at `/home/USER/_bknix/ramdisk`
// which should be shared by all loco processes (for the given user).
//
// Register it as a dependency for a systemd dependency.
Loco::dispatcher()->addListener('loco.systemd.export', function($e) {
  $ramdiskPath = 'home/' . getenv('USER') . '/_bknix/ramdisk';
  $ramdiskSvcName = \Loco\Utils\SystemdUtil::escapePath($ramdiskPath);
  $ramdiskSvcFile = "/etc/systemd/system/{$ramdiskSvcName}.mount";
  if (file_exists($ramdiskSvcFile)) {
    // TODO: Consider changing this `RequiresMountsFor=`
    $e['ini']['Unit'][] = "Requires=$ramdiskSvcFile";
  }
});
