/**
 * The `dfl` list identifies the lowest recommended versions of the system requirements.
 *
 * We rely on a mix of packages from Nix upstream v19.09 (`pkgs`), v18.09 (`pkgs_1809`), and
 * custom forks (`bkpkgs`).
 */
let
    pkgs = import (import ../../pins/19.09.nix) {};
    pkgs_1809 = import (import ../../pins/18.09.nix) {};
    pkgs_2105 = import (import ../../pins/21.05.nix) {};
    pkgs_2111 = import (import ../../pins/21.11.nix) {};
    bkpkgs = import ../../pkgs;

in (import ../base/default.nix) ++ (import ../mgmt/default.nix) ++ [

    bkpkgs.php80
    pkgs_2105.nodejs-14_x
    pkgs_2111.apacheHttpd
    pkgs_1809.mailcatcher
    pkgs_2105.memcached
    pkgs_1809.mysql57
    pkgs_2105.redis
    bkpkgs.transifexClient

]
