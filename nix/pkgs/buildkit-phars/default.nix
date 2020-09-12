/*
{pkgs ? import <nixpkgs> { inherit system; },
  system ? builtins.currentSystem,
  mysql ? pkgs.mysql57,
  node ? pkgs.nodejs-6_x,
  php ? pkgs.php72,
  # phpPackages ? pkgs.php72Packages
  }:
*/

{pkgs ? import <nixpkgs> { inherit system; },
  system ? builtins.currentSystem,
  noDev ? false,
  php ? pkgs.php72
}:

let
  stdenv = pkgs.stdenv;
  fetchurl = pkgs.fetchurl;

  phars = rec {
    _codecept-php5.phar = fetchurl { url = http://codeception.com/releases/2.3.6/php54/codecept.phar; sha256 = "1zgx567dm15ldz6f7wa990p61xgmw7w85dqqgmdz8lid5fdbi9cf"; executable = true; };
    _codecept-php7.phar = fetchurl { url = http://codeception.com/releases/2.3.6/codecept.phar; sha256 = "0galyryymdl2b9kdz212d7f2dcv76xgjws6j4bihr23sacamd029"; executable = true; };
    amp                 = fetchurl { url = https://download.civicrm.org/amp/amp.phar-2018-09-29-73136a8b; sha256 = "0xz7m6p6a1c9b45kr5g0knmlg0ciq01y3plnf6kkrcyavrfawj0v"; executable = true; };
    box                 = fetchurl { url = https://github.com/box-project/box2/releases/download/2.7.5/box-2.7.5.phar; sha256 = "1ky8rlh0nznwyllps7j6l7sz79wrn7jdds35lg90f0ycgag1xfc1"; executable = true; };
    civici              = fetchurl { url = https://download.civicrm.org/civici/civici-0.1.2.phar; sha256 = "0qclwg1yakij1jvlx67hshi79iil9blrmycshwvc6pb3q9cd6qa6"; executable = true; };
    civistrings         = fetchurl { url = https://download.civicrm.org/civistrings/civistrings.phar-2018-04-11-93987d92; sha256 = "07z2i8pllcfz471h1ph4d3amnq9x6l4d5l1r3p097gs42mnlj0bh"; executable = true; };
    civix               = fetchurl { url = https://download.civicrm.org/civix/civix.phar-2018-12-04-1d9c1734; sha256 = "0i9zr7mz5jabd253vi822ccv00kib8c9z80lk5ylcp47803mxcjm"; executable = true; };
    cv                  = fetchurl { url = https://download.civicrm.org/cv/cv.phar-2018-12-04-eefce0d0; sha256 = "183ymdbvm3ni932ilhsn41ykgx5s2is64p940ph8vvhrs34as8jz"; executable = true; };
    drush8              = fetchurl { url = https://github.com/drush-ops/drush/releases/download/8.1.17/drush.phar; sha256 = "1gz75nrq3jvpvi9n453gfzkhfk7axix92961hvbi475k2984qs1d"; executable = true; };
    git-scan            = fetchurl { url = https://download.civicrm.org/git-scan/git-scan.phar-2017-06-28-101620c7; sha256 = "02sdwrh0z5m17s6mkicj2kq3b044vsl921kllrpi63qrf7zklja1"; executable = true; };
    joomla              = fetchurl { url = https://download.civicrm.org/joomlatools-console/joomla.phar-2017-06-19-62ff6a9df; sha256 = "03amn61aps8vyd21ssw8fz0ff3znjmkf95av35d65n0i0vbss3i3"; executable = true; };
    phpunit4            = fetchurl { url = https://phar.phpunit.de/phpunit-4.8.21.phar; sha256 = "1yjkm44q11iyjymci785yms94p5qbfdwxz9gzsjsipgg0cv6zggq"; executable = true; };
    phpunit5            = fetchurl { url = https://phar.phpunit.de/phpunit-5.phar; sha256 = "0nhr361k528q9spz0w0vx3s86rxpvzka5a0kx1x7g9iiias0zl4x"; executable = true; };
    wp                  = fetchurl { url = https://github.com/wp-cli/wp-cli/releases/download/v2.0.1/wp-cli-2.0.1.phar; sha256 = "0qrbmlr876l76xqfvv6gypw9kvvla4r591yzp969y3bzi92xn0g3"; executable = true; };
  };

  pharLinkCommand = thePhars: pharName:
    let pharPath = builtins.getAttr pharName thePhars;
    in ("ln -s " + (builtins.toString pharPath) + " " + pharName);
    # in "ln -s $pharPath $out/bin/$pharName";
    # in "ln -s " ++ pharPath ++ " $out/bin/" ++ pharName;
    # in "hello";

in stdenv.mkDerivation rec {
  name = "buildkit";

  pharLinkCommands = builtins.concatStringsSep "\n" (map (pharLinkCommand phars) (builtins.attrNames phars));
  buildInputs = [php];
  buildCommand = ''
    mkdir $out $out/bin
    pushd $out/bin
      echo "((   ${pharLinkCommands} ))"
    popd
  '';

}
/*
    ln -s ${phars._codecept-php5.phar} $out/bin/_codecept-php5.phar
    ln -s ${phars._codecept-php7.phar} $out/bin/_codecept-php7.phar
    ln -s ${phars.amp} $out/bin/amp
    ln -s ${phars.box} $out/bin/box
    ln -s ${phars.civici} $out/bin/civici
    ln -s ${phars.civistrings} $out/bin/civistrings
    ln -s ${phars.civix} $out/bin/civix
    ln -s ${phars.cv} $out/bin/cv
    ln -s ${phars.drush8} $out/bin/drush
    ln -s ${phars.drush8} $out/bin/drush8
    ln -s ${phars.git-scan} $out/bin/git-scan
    ln -s ${phars.joomla} $out/bin/joomla
    ln -s ${phars.phpunit4} $out/bin/phpunit4
    ln -s ${phars.phpunit5} $out/bin/phpunit5
    ln -s ${phars.wp} $out/bin/wp

*/