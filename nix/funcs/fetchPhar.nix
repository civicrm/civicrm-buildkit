/**
 * fetchPhar - A very small function download a PHAR executable and
 * register in the `bin/` folder.
 *
 * These PHARs are *not* statically linked to PHP. You will have to
 * mix-in your own PHP-CLI.
 *
 * Usage:
 *   let
 *     fetchPhar = pkgs.callPackage (import ./fetchPhar.nix) {};
 *     box = fetchPhar {
 *       name = "box";
 *       url = "https://github.com/box-project/box/releases/download/4.3.7/box.phar";
 *       sha256 = "...";
 *     }
 *   in ...
 */

{ stdenv, fetchurl }: phar:

stdenv.mkDerivation rec {
  name = phar.name;
  src = fetchurl {
    url = phar.url;
    sha256 = phar.sha256;

    ## Setting `executable=true` would be better... except that `fetchurl` will
    ## switch to nix's proprietary flavor of sha256 (ie "recursive" mode with
    ## NAR wrapping). That would prohibit us from using standard/interoperable
    ## checksums. See: https://nixos.wiki/wiki/Nix_Hash
    executable = false;
  };
  buildInputs = [ ];
  buildCommand = ''
    mkdir $out $out/bin
    pushd $out/bin
      cp ${src} $out/bin/${name}
      chmod +x $out/bin/${name}
    popd
  '';
}
