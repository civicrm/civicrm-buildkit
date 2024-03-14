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
    isAppleM1 = stdenv.isDarwin && stdenv.isAarch64;

in (import ../base/default.nix) ++ (import ../mgmt/default.nix) ++ [

    php
    dists.default.nodejs-14_x
    dists.default.apacheHttpd
    dists.default.mailhog
    dists.default.memcached
    dbms
    dists.default.redis
    dists.bkit.transifexClient

] ++ (if isAppleM1 then [] else [dists.default.chromium])
