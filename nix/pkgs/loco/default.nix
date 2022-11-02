let

    pkgs = (import ../../pins).default;
    stdenv = pkgs.stdenv;

in stdenv.mkDerivation rec {

    name = "loco";
    src = pkgs.fetchurl {
      url = https://github.com/totten/loco/releases/download/v0.5.2/loco-0.5.2.phar;
      sha256 = "0x2hxs5p9nmr6cvpqqvfjxna9biwkxj7rblq698xa4k2csj5nh8r";
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
