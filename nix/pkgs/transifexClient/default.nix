# with import <nixpkgs> {};
with import (import ../../pins/21.05.nix) {};
with python37.pkgs;

let

  transifexClient = python37.pkgs.callPackage ./transifexClient.nix { };

in transifexClient
