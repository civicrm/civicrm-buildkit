let
    dists = import ../../pins;

in (import ../base/default.nix) ++ (import ../mgmt/default.nix) ++ [

    dists.bkit.php80
    dists.default.nodejs-14_x
    dists.default.apacheHttpd
    dists.default.mailhog
    dists.default.memcached
    dists.v2105.mariadb     ## MariaDB 10.5
    # dists.default.mariadb ## Currently MariaDB 10.6
    dists.default.redis
    dists.bkit.transifexClient

]
