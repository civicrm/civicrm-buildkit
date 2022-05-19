/**
 * The `min` list identifies the lowest recommended versions of the system requirements.
 *
 * The `dists` var provides a list of major releases of Nix upstream (eg v19.09 <=> dists.v1909).
 */
let
    dists = import ../../pins;

in (import ../base/default.nix) ++ (import ../mgmt/default.nix) ++ [

    dists.bkit.php72
    dists.v2105.nodejs-14_x
    dists.v2111.apacheHttpd
    dists.v1809.mailcatcher
    dists.default.memcached
    dists.bkit.mysql57
    dists.default.redis
    dists.bkit.transifexClient

]
