/**
 * Provide a list of packages which we have defined or customized locally.
 *
 * TODO: Consider using callPackages convention, e.g. http://lethalman.blogspot.com/2014/09/nix-pill-13-callpackage-design-pattern.html
 */

let

  pkgs = (import ../pins).default;
  stdenv = pkgs.stdenv;
  fetchPhar = (import ../funcs).fetchPhar;

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
   php80 = import ./php80/default.nix;
   php81 = import ./php81/default.nix;
   php82 = import ./php82/default.nix;
   transifexClient = import ./transifexClient/default.nix;
   ramdisk = callPackage (fetchTarball https://github.com/totten/ramdisk/archive/v0.1.1.tar.gz) {};

   # We don't actually modify the tzdata package, but we should have a singular pinning so that it same pkg is used in different flows.
   tzdata = pkgs.tzdata;

   box = fetchPhar {
     name = "box";
     url = https://github.com/box-project/box/releases/download/4.3.8/box.phar;
     sha256 = "sha256-4OVJUwLK9ZbEOPeF0IETkA6jQCPHvKpKaYyHghCiduQ=";
   };

   composer = fetchPhar {
     name = "composer";
     url = https://github.com/composer/composer/releases/download/2.3.10/composer.phar;
     sha256 = "sha256-krj5MTB2rzcTDXE68PgUaRtc4ezjZmj1OI0UtffOBUI=";
   };

   loco = fetchPhar {
     name = "loco";
     url = https://github.com/totten/loco/releases/download/v0.7.1/loco-0.7.1.phar;
     sha256 = "ckF3GN1rQYLZIrXG5mdS/kfRl3il3/PpH6OwCqVagsc=";
   };

   phive = fetchPhar {
     name = "phive";
     url = "https://github.com/phar-io/phive/releases/download/0.15.2/phive-0.15.2.phar";
     sha256 = "sha256-3uXSkAFl+EHt3Dr2X61Mg+JxUyqXfmXeewLRXsg3dck=";
   };

   phpunit8 = fetchPhar {
     name = "phpunit8";
     url = "https://phar.phpunit.de/phpunit-8.5.27.phar";
     sha256 = "sha256-LmJP8mj77jrNOEm9XI/6ktI0FngQsmLBS1qy7C8wNUo=";
   };

   phpunit9 = fetchPhar {
     name = "phpunit9";
     url = "https://phar.phpunit.de/phpunit-9.6.5.phar";
     sha256 = "sha256-+sFZ5FIVdhZ+/84/mGaVvyQHyDuile35r2FRSGpVHx8=";
   };

   pogo = fetchPhar {
     name = "pogo";
     url = https://github.com/totten/pogo/releases/download/v0.5.0/pogo-0.5.0.phar;
     sha256 = "heH1JFa3EGz069C+7a4YKtLEDYXShTAg0eIjx2jgASk=";
   };

}
