# with import <nixpkgs> {};
with import (import ../../pins/19.09.nix) {};
with python37.pkgs;

let

  transifexClient = python37.pkgs.callPackage ./transifexClient.nix { };

in transifexClient
