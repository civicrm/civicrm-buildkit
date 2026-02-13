/**
 * Provide a list of packages which we have defined or customized locally.
 *
 * TODO: Consider using callPackages convention, e.g. http://lethalman.blogspot.com/2014/09/nix-pill-13-callpackage-design-pattern.html
 */

let

  dists = (import ../pins);
  pkgs = dists.default;
  stdenv = pkgs.stdenv;
  isAppleM1 = stdenv.isDarwin && stdenv.isAarch64;

  fetchPhar = (import ../funcs).fetchPhar;
  jsonContent = builtins.fromJSON (builtins.readFile ../../phars.json);
  mapAttrs = (f: set: builtins.listToAttrs (builtins.map (attr: { name = attr; value = f attr set.${attr}; }) (builtins.attrNames set)));
  jsonToPhar = name: attrs: fetchPhar {
    name = name;
    url = attrs.url;
    sha256 = attrs.sha256;
  };
  pharDirectives = (mapAttrs jsonToPhar jsonContent);

  callPackage = path: overrides:
    let f = import path;
    in f ((builtins.intersectAttrs (builtins.functionArgs f) pkgs) // overrides);

  ## ifSupported: If the "condition" is true, then return "value". Otherwise, throw an error.
  ifSupported = name: condition: value: (if condition then value else throw "Package ${name} is unsupported in this environment");
  # ifSupported = name: condition: value: (if condition then value else null);

in pharDirectives // rec {

   mysql57 = dists.v2205.mysql57;
   mysql80 = dists.default.mysql80;
   mysql84 = dists.v2505.mysql84;
   mysql90 = dists.v2405.mysql90; ## Deprecated
   mysql93 = dists.v2505.mysql93;
   mariadb106 = dists.v2205.mariadb;
   mariadb1011 = dists.v2505.mariadb;

   nodejs_22 = dists.v2505.nodejs;

   bknixPhpstormAdvisor = import ./bknixPhpstormAdvisor/default.nix;
   bknixProfile = import ./bknixProfile/default.nix;
   php74 = import ./php74/default.nix;
   php80 = import ./php80/default.nix;
   php81 = import ./php81/default.nix;
   php82 = import ./php82/default.nix;
   php83 = import ./php83/default.nix;
   php84 = import ./php84/default.nix;
   php85 = import ./php85/default.nix;
   transifexClient = import ./transifexClient/default.nix;
   ramdisk = callPackage (fetchTarball "https://github.com/totten/ramdisk/archive/v0.1.2.tar.gz") {};

   # We don't actually modify the tzdata package, but we should have a singular pinning so that it same pkg is used in different flows.
   tzdata = pkgs.tzdata;

}
