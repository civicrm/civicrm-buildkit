/**
 * This shell is suitable for compiling civix.phar.... and not much else.
 *
 * Ex: `nix-shell --run ./build.sh`
 */
# { pkgs ? import <nixpkgs> {} }:
let
  pkgSrc = fetchTarball {
    url = "https://github.com/nixos/nixpkgs/archive/ce6aa13369b667ac2542593170993504932eb836.tar.gz";
    sha256 = "0d643wp3l77hv2pmg2fi7vyxn4rwy0iyr8djcw1h5x72315ck9ik";
  };
  pkgs = import pkgSrc {};
  myphp = pkgs.php74.buildEnv {
    extraConfig = ''
      memory_limit=-1
    '';
  };

in

  pkgs.mkShell {
    # nativeBuildInputs is usually what you want -- tools you need to run
    nativeBuildInputs = [ myphp pkgs.php74Packages.composer ];
}
