/**
 * The `max` list identifies the highest recommended versions of the system requirements.
 *
 * The `dists` var provides a list of major releases of Nix upstream (eg v19.09 <=> dists.v1909).
 */
let
    dists = import ../../pins;

in (import ../base/default.nix) ++ (import ../mgmt/default.nix) ++ [

    dists.bkit.php80
    dists.v2105.nodejs-14_x
    dists.v2111.apacheHttpd
    dists.v1809.mailcatcher
    dists.v2105.memcached
    /* dists.default.mariadb */
    dists.v2111.mysql80
    dists.v2105.redis
    dists.bkit.transifexClient

]
