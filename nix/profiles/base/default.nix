/**
 * The `base` profile defines a series of common CLI utilities that rarely change.
 */
let
    dists = import ../../pins;
    pkgs = dists.default;

in [
    pkgs.ansi2html
    pkgs.bzip2
    dists.bkit.bknixProfile
    pkgs.curl
    pkgs.gettext
    pkgs.git
    pkgs.gitAndTools.hub
    pkgs.gnugrep
    pkgs.gnused
    pkgs.gnutar
    pkgs.hostname
    pkgs.moreutils
    pkgs.ncurses
    pkgs.patch
    pkgs.rsync
    pkgs.subversion
    dists.bkit.tzdata
    pkgs.unzip
    pkgs.which
    pkgs.zip
] ++ (if pkgs.glibcLocales != null then [pkgs.glibcLocales] else [] )
