/**
 * This folder aims to help users setup _profiles_ which include a long
 * all the recommended development tools. Each item returned here is a
 * list of packages that can be installed in (one of) your profile(s).
 */
let
  phpXXmXX = import ./phpXXmXX/default.nix;
  dists = import ../pins;

  ## Some older packages aren't buildable on Apple M1, so we use closest match.
  stdenv = dists.default.stdenv;
  isAppleM1 = stdenv.isDarwin && stdenv.isAarch64;

  oldestAvailableMysql = (if isAppleM1 then dists.bkit.mysql80 else dists.bkit.mysql57);

in rec {

   /* ---------- Partial profiles; building-blocks ---------- */

   /**
    * Common CLI utilities shared by all other profiles
    */
   base = import ./base/default.nix;

   /**
    * bknix-specific management utilities
    */
   mgmt = import ./mgmt/default.nix;

   /* ---------- Full profiles ---------- */

   php73m57 = phpXXmXX { php = dists.bkit.php73; dbms = dists.bkit.mysql57; };
   php73m80 = phpXXmXX { php = dists.bkit.php73; dbms = dists.bkit.mysql80; };
   php73m84 = phpXXmXX { php = dists.bkit.php73; dbms = dists.bkit.mysql84; };
   php73r105 = phpXXmXX { php = dists.bkit.php73; dbms = dists.bkit.mariadb105; };
   php73r106 = phpXXmXX { php = dists.bkit.php73; dbms = dists.bkit.mariadb106; };

   php74m57 = phpXXmXX { php = dists.bkit.php74; dbms = dists.bkit.mysql57; };
   php74m80 = phpXXmXX { php = dists.bkit.php74; dbms = dists.bkit.mysql80; };
   php74m84 = phpXXmXX { php = dists.bkit.php74; dbms = dists.bkit.mysql84; };
   php74r105 = phpXXmXX { php = dists.bkit.php74; dbms = dists.bkit.mariadb105; };
   php74r106 = phpXXmXX { php = dists.bkit.php74; dbms = dists.bkit.mariadb106; };

   php80m57 = phpXXmXX { php = dists.bkit.php80; dbms = dists.bkit.mysql57; };
   php80m80 = phpXXmXX { php = dists.bkit.php80; dbms = dists.bkit.mysql80; };
   php80m84 = phpXXmXX { php = dists.bkit.php80; dbms = dists.bkit.mysql84; };
   php80r105 = phpXXmXX { php = dists.bkit.php80; dbms = dists.bkit.mariadb105; };
   php80r106 = phpXXmXX { php = dists.bkit.php80; dbms = dists.bkit.mariadb106; };

   php81m57 = phpXXmXX { php = dists.bkit.php81; dbms = dists.bkit.mysql57; };
   php81m80 = phpXXmXX { php = dists.bkit.php81; dbms = dists.bkit.mysql80; };
   php81m84 = phpXXmXX { php = dists.bkit.php81; dbms = dists.bkit.mysql84; };
   php81r105 = phpXXmXX { php = dists.bkit.php81; dbms = dists.bkit.mariadb105; };
   php81r106 = phpXXmXX { php = dists.bkit.php81; dbms = dists.bkit.mariadb106; };

   php82m57 = phpXXmXX { php = dists.bkit.php82; dbms = dists.bkit.mysql57; };
   php82m80 = phpXXmXX { php = dists.bkit.php82; dbms = dists.bkit.mysql80; };
   php82m84 = phpXXmXX { php = dists.bkit.php82; dbms = dists.bkit.mysql84; };
   php82r105 = phpXXmXX { php = dists.bkit.php82; dbms = dists.bkit.mariadb105; };
   php82r106 = phpXXmXX { php = dists.bkit.php82; dbms = dists.bkit.mariadb106; };

   php83m57 = phpXXmXX { php = dists.bkit.php83; dbms = dists.bkit.mysql57; };
   php83m80 = phpXXmXX { php = dists.bkit.php83; dbms = dists.bkit.mysql80; };
   php83m84 = phpXXmXX { php = dists.bkit.php83; dbms = dists.bkit.mysql84; };
   php83r105 = phpXXmXX { php = dists.bkit.php83; dbms = dists.bkit.mariadb105; };
   php83r106 = phpXXmXX { php = dists.bkit.php83; dbms = dists.bkit.mariadb106; };

   /**
    * These aliases represent the current minimum/maximum, as viewed from
    * the perspective of dev/master. In particular:
    *   - min: The oldest supported+runnable version
    *   - max: the newest supported+runnable version
    *   - edge: The bleeding-edge. Not yet supported. Partially runnable.
    *   - old: A recent/older version
    *   - dfl: A typical default. Corresponds to PR testing.
    *   - alt: An alternative version. Basically, with MariaDB and middle-of-the-road PHP.
    */
   old = phpXXmXX { php = dists.bkit.php73; dbms = oldestAvailableMysql; };
   min = phpXXmXX { php = dists.bkit.php74; dbms = oldestAvailableMysql; };
   dfl = phpXXmXX { php = dists.bkit.php82; dbms = oldestAvailableMysql; };
   alt = php80r105;
   max = php82m80;
   edge = php83m80;

   /**
    * These aliases are short-hand. They're not intended for CI testing,
    * where you shold probably consider mysql versions more intentionally.
    * But they may be useful for quick/local hacking.
    */
   php73 = php73m80;
   php74 = php74m80;
   php80 = php80m80;
   php81 = php81m80;
   php82 = php82m80;
   php83 = php83m80;

   /**
    * Tool-chain used during releases
    */
   releaser = import ./releaser/default.nix;

}
