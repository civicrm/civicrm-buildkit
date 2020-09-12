/**
 * The `max` list identifies the highest recommended versions of the system requirements.
 *
 * We rely on a mix of packages from Nix upstream v19.09 (`pkgs`), v18.09 (`pkgs_1809`), and
 * custom forks (`bkpkgs`).
 */
let
    pkgs = import (import ../../pins/19.09.nix) {};
    pkgs_1809 = import (import ../../pins/18.09.nix) {};
    bkpkgs = import ../../pkgs;

in (import ../base/default.nix) ++ (import ../mgmt/default.nix) ++ [

    bkpkgs.php74
    pkgs_1809.nodejs-8_x
    pkgs.apacheHttpd
    pkgs_1809.mailcatcher
    pkgs.memcached
    /* pkgs.mariadb */
    pkgs.mysql80
    pkgs.redis
    bkpkgs.transifexClient

]
