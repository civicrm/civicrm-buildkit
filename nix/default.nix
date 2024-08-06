let
    pins = import ./pins;
    pkgs = pins.default;
    stdenv = pkgs.stdenv;
    profiles = import ./profiles;

    mapAttrs = (f: set: builtins.listToAttrs (builtins.map (attr: { name = attr; value = f attr set.${attr}; }) (builtins.attrNames set)));

    mkCliDerivation = profileName: packageList: stdenv.mkDerivation rec {
      name = "bknix";
      buildInputs = packageList ++ [ pkgs.makeWrapper ];
      shellHook = ''
        PS1='\n\[\033[1;32m\][${profileName}:\w]\$\[\033[0m\] '

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
     *   nix-shell -A bkpkgs.ph83
     *   nix-shell -A bkpkgs.php73
     *   nix-env -f . -i -A bkpkgs.php83
     *   nix-env -f . -i -A bkpkgs.php73
     */

    allClis // {
      inherit profiles;
      bkpkgs = pins.bkit;
      pkgs = pins.bkit;
      pins = pins;
      funcs = import ./funcs;
    }
