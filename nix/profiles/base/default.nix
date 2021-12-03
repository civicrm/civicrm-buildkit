/**
 * The `base` profile defines a series of common CLI utilities that rarely change.
 */
let
    dists = import ../../pins;
    pkgs = dists.v2105;

in [
    pkgs.bzip2
    dists.bkit.bknixProfile
    pkgs.curl
    pkgs.gettext
    pkgs.git
    pkgs.gitAndTools.hub
    pkgs.gnugrep
    pkgs.gnutar
    pkgs.hostname
    pkgs.moreutils
    pkgs.ncurses
    pkgs.patch
    pkgs.rsync
    pkgs.unzip
    pkgs.which
    pkgs.zip
] ++ (if pkgs.glibcLocales != null then [pkgs.glibcLocales] else [] )
