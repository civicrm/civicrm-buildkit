/**
 * A _profile_ provides a list of recommended packages (such as PHP and bzip2).
 *
 * This script defines many profiles, including these three groups:
 *
 * - "combinations": Cartesian product of PHP x DBMS. Each of these is a profile:
 *
 *     php74m57 php74m80 php74m84 php74r105 php74r106
 *     php80m57 php80m80 php80m84 php80r105 php80r106
 *     php81m57 php81m80 php81m84 php81r105 php81r106
 *     php82m57 php82m80 php82m84 php82r105 php82r106
 *     php83m57 php83m80 php83m84 php83r105 php83r106
 *
 *     These are named for PHP+DBMS. However, the profiles also include
 *     many shared utilities (such as bzip2 and MailHog).
 *
 * - "aliasProfiles": These are convenience aliases. A few examples:
 *
 *     "min" (lowest supported version of PHP+MySQL; ex: "min=php80m57")
 *     "max" (highest supported version of PHP+MySQL; ex: "max=php84m84")
 *     "php80" (PHP 8.0 with some arbitrary DBMS; ex: "php80=php80m57")
 *
 *     The actual "aliasProfiles" are defined further down.
 *
 * - "helperProfiles": These oddballs can be used if one
 *   needs to build a similar/custom profile.
 */
let

  /**
   * ***************************************************
   * (Prelude) Import general information and utilities
   * ***************************************************
   *
   * In this section, we obtain the list of all PHP+DBMS
   * versions.
   */

  dists = import ../pins;

  ## Some older packages aren't buildable on Apple M1, so we use closest match.
  stdenv = dists.default.stdenv;

  attrsets = dists.default.lib;

  ## Example: rekeyRecord foo bar {foo_1=100;foo_2=200}
  ## Output:              ======> {bar_1=100;bar_2=200}
  rekeyRecord = prefixOld: prefixNew: record:
    let
      rekey = key:
        if builtins.match "^${prefixOld}(.*)" key != null then
          "${prefixNew}${builtins.elemAt (builtins.match "^${prefixOld}(.*)" key) 0}"
        else
          key;
    in attrsets.mapAttrs' (k: v: { name=(rekey k); value=v; }) record;

  isValidProfile = x: (builtins.tryEval x).success;

  /**
   * ******************************
   * Import PHP and DBMS defintions
   * ******************************
   */

  ## phpVersions = { php74=PKG, php80=PKG, ... }
  phpVersions = (attrsets.filterAttrs (name: value: builtins.match "php[0-9]+" name != null) dists.bkit);

  ## mysqlVersions = { mysql57=PKG, mysql80=PKG, ... }
  mysqlVersions = (attrsets.filterAttrs (name: value: builtins.match "mysql[0-9]+" name != null) dists.bkit);

  ## mariadbVersions = { mariadb105=PKG, mariadb106=PKG, ...}
  mariadbVersions = (attrsets.filterAttrs (name: value: builtins.match "mariadb[0-9]+" name != null) dists.bkit);

  ## dbmsVersions = { m57=PKG, m80=PKG, r105=PKG, r106=PKG, ...}
  dbmsVersions = (rekeyRecord "mysql" "m" mysqlVersions) // (rekeyRecord "mariadb" "r" mariadbVersions);

  /**
   * ***************************************
   * Prepare all combinations of PHP x DBMS
   * ***************************************
   */

  ## Based on some PHP vX.X and some DBMS vX.X., make a full profile.
  ## function( php, dbms ) => full-package-list
  phpXXmXX = import ./phpXXmXX/default.nix;

  combinations = builtins.foldl' (acc: phpVersion:
    builtins.foldl' (innerAcc: dbmsVersion:
      innerAcc // {
        "${phpVersion}${dbmsVersion}" = phpXXmXX { php = phpVersions.${phpVersion}; dbms = dbmsVersions.${dbmsVersion}; };
      }
    ) acc (builtins.attrNames dbmsVersions)
  ) {} (builtins.attrNames phpVersions);

  /**
   * **********************
   * Prepare alias profiles
   * **********************
   */
  aliasProfiles = rec {

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
   old = combinations.php74m57;
   min = combinations.php81m57;
   dfl = combinations.php82m57; /* Test suites run faster on MySQL 5.7 */
   alt = combinations.php81r106;
   max = combinations.php83m80;
   edge = combinations.php84m80;

   /**
    * These aliases are short-hand. They're not intended for CI testing,
    * where you shold probably consider mysql versions more intentionally.
    * But they may be useful for quick/local hacking.
    */
   php74 = combinations.php74m80;
   php80 = combinations.php80m80;
   php81 = combinations.php81m80;
   php82 = combinations.php82m80;
   php83 = combinations.php83m80;
   php84 = combinations.php84m80;
   php85 = combinations.php85m80;

  };

  /**
   * ********************************************
   * Misc profiles. For downstream customization.
   * ********************************************
   */
  helperProfiles = rec {

   /**
    * Common CLI utilities shared by all other profiles
    */
   base = import ./base/default.nix;

   /**
    * bknix-specific management utilities
    */
   mgmt = import ./mgmt/default.nix;

   /**
    * Tool-chain used during releases
    */
   releaser = import ./releaser/default.nix;

  };

in attrsets.filterAttrs (k: v: isValidProfile v) (helperProfiles // combinations // aliasProfiles)

## FIXME: It might be nicer to return the full list.  This would mean that
## commands like `nix-shell -A phpXXmXX` would raise slightly more precise
## error when running on unsupported environment.  But then you also have to
## update the publication-steps (doc/publish.md) to omit invalid items.
