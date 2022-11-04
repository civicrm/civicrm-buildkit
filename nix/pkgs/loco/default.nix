let

    pkgs = (import ../../pins).default;
    stdenv = pkgs.stdenv;

in stdenv.mkDerivation rec {

    name = "loco";
    src = pkgs.fetchurl {
      url = https://github.com/totten/loco/releases/download/v0.5.4/loco-0.5.4.phar;
      sha256 = "tGCAuBy4LVjxvcMXCIZuyXMy+qgfAdHFgpGpxWmshxs=";
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
