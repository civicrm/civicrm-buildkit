let

    pkgs = import (import ../../pins/19.09.nix) {};
    stdenv = pkgs.stdenv;

in stdenv.mkDerivation rec {

    name = "loco";
    src = pkgs.fetchurl {
      url = https://github.com/totten/loco/releases/download/v0.4.5/loco-0.4.5.phar;
      sha256 = "0n08663qzbzhbb44ny1pb8fsy8m734hgd9bcfnn4vdj59xlxlf0d";
      executable = true;
    };
    buildInputs = [ ];
    buildCommand = ''
      mkdir $out $out/bin
      pushd $out/bin
        ln -s ${src} $out/bin/${name}
      popd
    '';

}
