let

    pkgs = import (import ../../pins/19.09.nix) {};
    stdenv = pkgs.stdenv;

in stdenv.mkDerivation rec {

    name = "bknix-profile";
    src = ./src;
    buildInputs = [ pkgs.makeWrapper ];

    installPhase = ''
        mkdir -p $out/bin
        makeWrapper ${src}/bknix-profile $out/bin/bknix-profile
    '';
}
