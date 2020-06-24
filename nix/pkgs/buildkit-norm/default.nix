{pkgs ? import <nixpkgs> {
    inherit system;
  },
  system ? builtins.currentSystem,
  noDev ? false,
  mysql ? pkgs.mysql57,
  node ? pkgs.nodejs-6_x,
  php ? pkgs.php72,
  # phpPackages ? pkgs.php72Packages
  }:

let
  stdenv = pkgs.stdenv;

in stdenv.mkDerivation rec {
    name = "buildkit";

    src = /Users/totten/tmp/civicrm-buildkit-master-civibuild-home;

    #src = pkgs.fetchFromGitHub {
    #  owner = "civicrm";
    #  repo = "civicrm-buildkit";
    #  rev = "FIXME";
    #  sha256 = "FIXME";
    #};

    # buildInputs = [ php phpPackages.composer ];
    # builder = "${src}/scripts/nix-builder.sh";
    builder = "/Users/totten/bknix/civicrm-buildkit/src/nix-builder.sh";
    buildInputs = [
      php
      node
      mysql
      pkgs.bzip2
      pkgs.curl
      pkgs.git
      pkgs.gnutar
      pkgs.hostname
      pkgs.ncurses
      pkgs.patch
      pkgs.rsync
      pkgs.unzip
      pkgs.wget
      pkgs.which
      pkgs.zip
    ];
}
