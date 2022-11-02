let

    pkgs = (import ../../pins).default;
    stdenv = pkgs.stdenv;

in stdenv.mkDerivation rec {

    name = "loco";
    src = pkgs.fetchurl {
      url = https://github.com/totten/loco/releases/download/v0.5.3/loco-0.5.3.phar;
      sha256 = "bW0Y0NzpPNijO3EB3YSnMlxHGZFkGtRnNk8q0If9G/w=";
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
