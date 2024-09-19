## Build a wrapper for the "mysql" package which is more amenable to `loco`.

let
    dists = import ../../pins;
    pkgs = dists.default;
    original = pkgs.mysql80;

in pkgs.stdenv.mkDerivation rec {
  name = "mysql-loco";

  src = ./src;
  nativeBuildInputs = [ pkgs.makeWrapper pkgs.pkg-config pkgs.which original ];

  installPhase = ''
    mkdir -p $out/bin
    ${src}/makeWrapperDir.sh ${original}/bin $out/bin
  '';

  doCheck = false;
}
