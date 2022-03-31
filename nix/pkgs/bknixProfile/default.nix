let

    dists = import ../../pins;
    pkgs = dists.default;
    stdenv = pkgs.stdenv;

in stdenv.mkDerivation rec {

    name = "bknix-profile";
    src = ./src;
    buildInputs = [ pkgs.makeWrapper dists.bkit.tzdata ];

    installPhase = ''
        mkdir -p $out/bin
        makeWrapper ${src}/bknix-profile $out/bin/bknix-profile \
          --set-default TZDIR ${pkgs.tzdata}/share/zoneinfo
    '';
}
