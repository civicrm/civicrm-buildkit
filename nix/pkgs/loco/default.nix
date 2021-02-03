let

    pkgs = import (import ../../pins/19.09.nix) {};
    stdenv = pkgs.stdenv;

in stdenv.mkDerivation rec {

    name = "loco";
    src = pkgs.fetchurl {
      url = https://github.com/totten/loco/releases/download/v0.4.4/loco-0.4.4.phar;
      sha256 = "0bg7q0h835kvp9zhvk7a5ymfxazm3c16xh3x0yc7z0m2cx2s7n10";
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
