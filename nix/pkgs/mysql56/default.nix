/**
 * This builds mysql56. This version has never been published in nixpkgs. 
 * It's derived from a recent mysql57 build script.
 */
let
#  nixpkgs = import (import ../../pins/18.03.nix) {};
  nixpkgs = import (import ../../pins/19.09.nix) {};
  allPkgs = nixpkgs // pkgs;
  callPackage = path: overrides:
    let f = import path;
    in f ((builtins.intersectAttrs (builtins.functionArgs f) allPkgs) // overrides);
  pkgs = with nixpkgs; {
    mysql56 = callPackage ./5.6.x.nix {
      inherit (darwin) cctools developer_cmds;
      inherit (darwin.apple_sdk.frameworks) CoreServices;
      # boost = boost169; # Configure checks for specific version.
    };
  };
in pkgs