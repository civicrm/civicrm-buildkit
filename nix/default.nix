let

    pkgs = (import ./pins).default;
    stdenv = pkgs.stdenv;
    bkpkgs = import ./pkgs;
    profiles = import ./profiles;

    mapAttrs = (f: set: builtins.listToAttrs (builtins.map (attr: { name = attr; value = f attr set.${attr}; }) (builtins.attrNames set)));

    mkCliDerivation = profileName: packageList: stdenv.mkDerivation rec {
      name = "bknix";
      buildInputs = packageList ++ [ pkgs.makeWrapper ];
      shellHook = ''
        if [ ! -f ".loco/loco.yml" -a -f "../.loco/loco.yml" ]; then
          cd ..
        fi

        if [ -f ".loco/loco.yml" ]; then
          eval $(loco env --export)
          [ -f "./nix/etc/bashrc.local" ] && source "./nix/etc/bashrc.local"
        else
          echo "WARNING: The .loco/loco.yml not found. Environment may not be fully initialized. Please run nix-shell in the buildkit folder." 1>&2
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
