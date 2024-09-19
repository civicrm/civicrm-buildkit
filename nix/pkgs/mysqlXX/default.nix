## Build a wrapper for the "mysql" package which is more amenable to `loco`.
{ mysql }:

let
    dists = import ../../pins;
    pkgs = dists.default;

in pkgs.stdenv.mkDerivation rec {
  name = "mysql-loco";

  src = ./src;
  nativeBuildInputs = [ pkgs.which pkgs.findutils mysql ];

  installPhase = ''
    mkdir -p $out/bin
    ${src}/makeWrapperDir.sh ${mysql}/bin $out/bin
  '';

  doCheck = false;
}
