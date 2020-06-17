let

    pkgs = import (import ../../pins/18.03.nix) {};
    stdenv = pkgs.stdenv;

in stdenv.mkDerivation rec {

    name = "bknix-phpstorm-advisor";
    src = ./src;
    buildInputs = [ pkgs.makeWrapper ];

    installPhase = ''
        mkdir -p $out/bin
        makeWrapper ${src}/bknix-phpstorm-advisor $out/bin/bknix-phpstorm-advisor
    '';
}
