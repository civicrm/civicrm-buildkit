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

  ## These lists help generate every possible combination of {PHP}x{MySQL}, i.e.
  ##  - php73m57 php73m80 php73m84 php73r105 php73r106
  ##  - php74m57 php74m80 php74m84 php74r105 php74r106
  ##  - php80m57 php80m80 php80m84 php80r105 php80r106
  ##  - php81m57 php81m80 php81m84 php81r105 php81r106
  ##  - php82m57 php82m80 php82m84 php82r105 php82r106
  ##  - php83m57 php83m80 php83m84 php83r105 php83r106

  phpVersions = {
    php73 = dists.bkit.php73;
    php74 = dists.bkit.php74;
    php80 = dists.bkit.php80;
    php81 = dists.bkit.php81;
    php82 = dists.bkit.php82;
    php83 = dists.bkit.php83;
    php84 = dists.bkit.php84;
  };

  dbmsVersions = {
    m57 = dists.bkit.mysql57;
    m80 = dists.bkit.mysql80;
    m84 = dists.bkit.mysql84;
    m90 = dists.bkit.mysql90;
    r105 = dists.bkit.mariadb105;
    r106 = dists.bkit.mariadb106;
  };

  combinations = builtins.foldl' (acc: phpVersion:
    builtins.foldl' (innerAcc: dbmsVersion:
      innerAcc // {
        "${phpVersion}${dbmsVersion}" = phpXXmXX { php = phpVersions.${phpVersion}; dbms = dbmsVersions.${dbmsVersion}; };
      }
    ) acc (builtins.attrNames dbmsVersions)
  ) {} (builtins.attrNames phpVersions);


in combinations // rec {

   /* ---------- Partial profiles; building-blocks ---------- */

   /**
    * Common CLI utilities shared by all other profiles
    */
   base = import ./base/default.nix;

   /**
    * bknix-specific management utilities
    */
   mgmt = import ./mgmt/default.nix;

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
   alt = combinations.php80r105;
   max = combinations.php82m80;
   edge = combinations.php83m80;

   /**
    * These aliases are short-hand. They're not intended for CI testing,
    * where you shold probably consider mysql versions more intentionally.
    * But they may be useful for quick/local hacking.
    */
   php73 = combinations.php73m80;
   php74 = combinations.php74m80;
   php80 = combinations.php80m80;
   php81 = combinations.php81m80;
   php82 = combinations.php82m80;
   php83 = combinations.php83m80;
   php84 = combinations.php84m80;

   /**
    * Tool-chain used during releases
    */
   releaser = import ./releaser/default.nix;

}
