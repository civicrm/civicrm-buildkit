let

    pkgs = import (fetchTarball https://github.com/NixOS/nixpkgs-channels/archive/nixos-18.03.tar.gz) {};
    stdenv = pkgs.stdenv;
    bkpkgs = import ./pkgs;
    profiles = import ./profiles;

    mapAttrs = (f: set: builtins.listToAttrs (builtins.map (attr: { name = attr; value = f attr set.${attr}; }) (builtins.attrNames set)));

    mkCliDerivation = profileName: packageList: stdenv.mkDerivation rec {
      name = "bknix";
      buildInputs = packageList ++ [ pkgs.makeWrapper ];
      bknixDepsStr = builtins.concatStringsSep ":" packageList;
      buildCommand = ''
        mkdir "$out" "$out/bin"
        makeWrapper "${bkpkgs.launcher}/bin/bknix" $out/bin/bknix --prefix BKNIX_DEPS : "${bknixDepsStr}"
      '';
      shellHook = ''
        [ -z "$BKNIXDIR" ] && export BKNIXDIR="$PWD"
        eval $(bknix env)

        if [ -f "$BKNIXDIR/etc/bashrc.local" ]; then
          source "$BKNIXDIR/etc/bashrc.local"
        fi
    '';
    };

    allClis = mapAttrs mkCliDerivation profiles;

in

    /*
     * To allow a user to start a shell for a configuration, we return one eponymous derivation for each configuration (`allClis`).
     *
     *   nix-shell -A dfl
     *   nix-shell -A min
     *   nix-shell -A max
     *
     * To allow a user to install all the packages for a configuration, we return the profile packages-lists.
     *
     *   nix-env -f . -i -E 'f: f.profiles.dfl'
     *   nix-env -f . -i -E 'f: f.profiles.min'
     *   nix-env -f . -i -E 'f: f.profiles.max'
     *
     * To allow a user to run or install one of the forked packages, we return the bkpkgs set.
     *
     *   nix-shell -A bkpkgs.php56
     *   nix-shell -A bkpkgs.php70
     *   nix-env -f . -i -A bkpkgs.php56
     *   nix-env -f . -i -A bkpkgs.php70
     */

    allClis // { inherit profiles; inherit bkpkgs; }
