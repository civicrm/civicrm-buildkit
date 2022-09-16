/**
 * The `min` list identifies the lowest recommended versions of the system requirements.
 *
 * The `dists` var provides a list of major releases of Nix upstream (eg v19.09 <=> dists.v1909).
 */
let
    dists = import ../../pins;
    stdenv = dists.default.stdenv;
    ## Some older packages aren't buildable on Apple M1, so we use closest match.
    isAppleM1 = stdenv.isDarwin && stdenv.isAarch64;

in (import ../base/default.nix) ++ (import ../mgmt/default.nix) ++ [

    (if isAppleM1 then dists.bkit.php74 else dists.bkit.php72)
    dists.default.nodejs-14_x
    dists.v2111.apacheHttpd
    dists.v2111.mailhog
    dists.default.memcached
    (if isAppleM1 then dists.default.mysql80 else dists.v1809.mysql57)
    dists.default.redis
    dists.bkit.transifexClient

]
