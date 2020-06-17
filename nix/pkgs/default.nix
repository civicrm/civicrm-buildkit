/**
 * Provide a list of packages which we have defined or customized locally.
 *
 * TODO: Consider using callPackages convention, e.g. http://lethalman.blogspot.com/2014/09/nix-pill-13-callpackage-design-pattern.html
 */

let

  pkgs = import (import ../pins/18.09.nix) {};
  stdenv = pkgs.stdenv;
  callPackage = path: overrides:
    let f = import path;
    in f ((builtins.intersectAttrs (builtins.functionArgs f) pkgs) // overrides);

in rec {
   mysql55 = (import ./mysql55/default.nix).mysql55;
   mysql56 = (import ./mysql56/default.nix).mysql56;
   php56 = import ./php56/default.nix;
   php70 = import ./php70/default.nix;
   php71 = import ./php71/default.nix;
   php72 = import ./php72/default.nix;
   php73 = import ./php73/default.nix;
   bknixPhpstormAdvisor = import ./bknixPhpstormAdvisor/default.nix;
   bknixProfile = import ./bknixProfile/default.nix;
   php74 = import ./php74/default.nix;
   transifexClient = import ./transifexClient/default.nix;
   ramdisk = callPackage (fetchTarball https://github.com/totten/ramdisk/archive/v0.1.1.tar.gz) {};
   loco = callPackage (fetchTarball https://github.com/totten/loco/archive/v0.4.2.tar.gz) {};
   # loco = callPackage /PATH/TO/src/loco {};
}
