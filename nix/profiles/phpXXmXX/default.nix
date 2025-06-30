{ php, dbms }:

/**
 * These is an *almost complete* profile. It's just missing PHP and MySQL.
 * Call this function and supply specific versions of php/mysql.
 *
 * Example usage: `php74m80 = phpXXmXX { php=dists.bkit.php74; dbms=dists.bkit.mysql80 }`
 */
let
    dists = import ../../pins;
    stdenv = dists.default.stdenv;
    isApple = stdenv.isDarwin;

    isValidPackage = pkg: (builtins.tryEval pkg).success && pkg != null && pkg.type == "derivation";

in if (isValidPackage php) && (isValidPackage dbms)
  then (import ../base/default.nix) ++ (import ../mgmt/default.nix) ++ [

    php
    # dists.bkit.nodejs_14
    dists.bkit.nodejs_22
    dists.default.apacheHttpd
    dists.default.mailhog
    dists.default.memcached
    dbms
    dists.default.redis
    dists.bkit.transifexClient

  ] ++ (if isApple then [] else [dists.default.chromium])

  else throw "Unsupported: Some dependencies for this combination of PHP/MySQL are not available in this environment."
