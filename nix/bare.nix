let

    pkgs = (import ./pins).default;
    stdenv = pkgs.stdenv;
    bkpkgs = import ./pkgs;
    profiles = import ./profiles;

    mapAttrs = (f: set: builtins.listToAttrs (builtins.map (attr: { name = attr; value = f attr set.${attr}; }) (builtins.attrNames set)));

    mkCliDerivation = profileName: packageList: stdenv.mkDerivation rec {
      name = "bknix-bare";
      buildInputs = packageList ++ [ pkgs.makeWrapper ];
    };

    allClis = mapAttrs mkCliDerivation profiles;

in

    /*
     * To allow a user to start a shell for a configuration, we return one eponymous derivation for each configuration (`allClis`).
     *
     *   nix-shell nix/bare.nix -A dfl
     *   nix-shell nix/bare.nix -A min
     *   nix-shell nix/bare.nix -A max
     */

    allClis
