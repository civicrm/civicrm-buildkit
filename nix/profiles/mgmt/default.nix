/**
 * The `mgmt` profile provides bknix's process management utilities for
 * starting/stopping daemons.
 *
 * At time of writing, this profile represents the main difference between
 * the branches `master` and `master-loco`
 */
let
    dists = import ../../pins;
in [
    dists.bkit.bknixPhpstormAdvisor
    dists.bkit.loco
    dists.bkit.ramdisk
]
