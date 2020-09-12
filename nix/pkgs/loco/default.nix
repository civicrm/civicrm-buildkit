let

    pkgs = import (import ../../pins/19.09.nix) {};
    stdenv = pkgs.stdenv;

in stdenv.mkDerivation rec {

    name = "loco";
    src = pkgs.fetchurl {
      url = https://github.com/totten/loco/releases/download/v0.4.3/loco-0.4.3.phar;
      sha256 = "0g7avj2g0v5nbmnn2dzpdi8m0zw7igrb93gqqq81sir1kh1s7qm2";
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
