let

    pkgs = (import ../../pins).default;
    stdenv = pkgs.stdenv;

in stdenv.mkDerivation rec {

    name = "loco";
    src = pkgs.fetchurl {
      url = https://github.com/totten/loco/releases/download/v0.7.0/loco-0.7.0.phar;
      sha256 = "6lgw9iGNmkdlApHcb0AD3wgcMwP3RxD+Po84NCYbdsA=";
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
