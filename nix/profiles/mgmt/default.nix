/**
 * The `mgmt` profile provides bknix's process management utilities for
 * starting/stopping daemons.
 *
 * At time of writing, this profile represents the main difference between
 * the branches `master` and `master-loco`
 */
let
    pkgs = import (import ../../pins/19.09.nix) {};
    bkpkgs = import ../../pkgs;
in [
    bkpkgs.bknixPhpstormAdvisor
    bkpkgs.loco
    bkpkgs.ramdisk
]
