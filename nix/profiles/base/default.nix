/**
 * The `base` profile defines a series of common CLI utilities that rarely change.
 */
let
    pkgs = import (import ../../pins/19.09.nix) {};
    bkpkgs = import ../../pkgs;
in [
    pkgs.bzip2
    bkpkgs.bknixProfile
    pkgs.curl
    pkgs.gettext
    pkgs.git
    pkgs.gitAndTools.hub
    pkgs.gnugrep
    pkgs.gnutar
    pkgs.hostname
    pkgs.ncurses
    pkgs.patch
    pkgs.rsync
    pkgs.unzip
    pkgs.which
    pkgs.zip
] ++ (if pkgs.glibcLocales != null then [pkgs.glibcLocales] else [] )
