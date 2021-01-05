/**
 * This builds mysql80. This is a modified version of the nix package to use a later version of MySQL 8.0. 
 */
let
  nixpkgs = import (import ../../pins/20.09.nix) {};
  allPkgs = nixpkgs // pkgs;
  callPackage = path: overrides:
    let f = import path;
    in f ((builtins.intersectAttrs (builtins.functionArgs f) allPkgs) // overrides);
  pkgs = with nixpkgs; {
    mysql80 = callPackage ./8.0.x.nix {
      inherit (darwin) cctools developer_cmds;
      inherit (darwin.apple_sdk.frameworks) CoreServices;
      boost = boost172; # Configure checks for specific version.
    };
  };
in pkgs
