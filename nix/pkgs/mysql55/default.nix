/**
 * This is forked copy of the mainline mysql55. It adds options to enable additional storage engines.
 * It's a copy-paste job; if you know a more elegant way to override `cmakeFlags`, that'd
 * be awesome.
 */
let
  nixpkgs = import (import ../../pins/18.03.nix) {};
  allPkgs = nixpkgs // pkgs;
  callPackage = path: overrides:
    let f = import path;
    in f ((builtins.intersectAttrs (builtins.functionArgs f) allPkgs) // overrides);
  pkgs = with nixpkgs; {
    mysql55 = callPackage ./5.5.x.nix {
      inherit (darwin) cctools;
      inherit (darwin.apple_sdk.frameworks) CoreServices;
    };
  };
in pkgs