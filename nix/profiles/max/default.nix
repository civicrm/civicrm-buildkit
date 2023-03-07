/**
 * The maximum profile (`max`) uses the highest recommended versions of the system requirements.
 *
 * Note: The `dists` var provides a list of major releases of Nix upstream (eg v19.09 <=> dists.v1909).
 */
let
    dists = import ../../pins;

in (import ../base/default.nix) ++ (import ../mgmt/default.nix) ++ [

    dists.bkit.php81
    dists.default.nodejs-14_x
    dists.default.apacheHttpd
    dists.default.mailhog
    dists.default.memcached
    dists.default.mysql80
    dists.default.redis
    dists.bkit.transifexClient

]
