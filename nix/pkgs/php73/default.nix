# Make an own version of php with the new php.ini from above
# add all extensions needed as buildInputs and don't forget to load them in the php.ini above

let
    pkgs = import (import ../../pins/19.09.nix) {};
    ## TEST ME: Do we need to set config.php.mysqlnd = true?

    stdenv = pkgs.stdenv;

    phpRuntime = pkgs.php73;
    phpPkgs = pkgs.php73Packages;
    phpExtras = import ../phpExtras/default.nix {
      pkgs = pkgs;
      php = pkgs.php73; ## Hmm, a little bit loopy, but this effectively how other extensions resolve the loopines..
    };

    phpIniSnippet = ../phpCommon/php.ini;
    phpIni = pkgs.runCommand "php.ini"
    { options = ''
            zend_extension=${phpPkgs.xdebug}/lib/php/extensions/xdebug.so
            extension=${phpPkgs.redis}/lib/php/extensions/redis.so
            extension=${phpPkgs.yaml}/lib/php/extensions/yaml.so
            extension=${phpPkgs.memcached}/lib/php/extensions/memcached.so
            extension=${phpExtras.timecop}/lib/php/extensions/timecop.so
            extension=${phpExtras.runkit7_3}/lib/php/extensions/runkit7.so
            openssl.cafile=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
      ''

       ## Per https://bugs.php.net/bug.php?id=77260 -- in php73, pcre.jit uses MAP_JIT which is quirky on diff versions of macOS
       + (if stdenv.isDarwin then "pcre.jit=0\n" else "");

       ## TEST ME: Do we still need imagick? Can we get away with gd nowadays?
       #    extension=${phpPkgs.imagick}/lib/php/extensions/imagick.so
    }
    ''
      cat "${phpRuntime}/etc/php.ini" > $out
      echo "$options" >> $out
      cat "${phpIniSnippet}" >> $out
    '';

    phpOverride = stdenv.mkDerivation rec {
        name = "bknix-php73";
        ## TEST ME: Do we still need imagick? Can we get away with gd nowadays?
        # buildInputs = [phpRuntime phpPkgs.xdebug phpPkgs.redis phpPkgs.yaml phpPkgs.memcached phpPkgs.imagick phpExtras.timecop phpExtras.runkit7_3 pkgs.makeWrapper pkgs.cacert];
        buildInputs = [phpRuntime phpPkgs.xdebug phpPkgs.redis phpPkgs.yaml phpPkgs.memcached phpExtras.timecop phpExtras.runkit7_3 pkgs.makeWrapper pkgs.cacert];
        buildCommand = ''
          makeWrapper ${phpRuntime}/bin/phar $out/bin/phar
          makeWrapper ${phpRuntime}/bin/php $out/bin/php --add-flags -c --add-flags "${phpIni}"
          makeWrapper ${phpRuntime}/bin/php-cgi $out/bin/php-cgi --add-flags -c --add-flags "${phpIni}"
          makeWrapper ${phpRuntime}/bin/php-fpm $out/bin/php-fpm --add-flags -c --add-flags "${phpIni}"
          makeWrapper ${phpRuntime}/bin/phpdbg $out/bin/phpdbg --add-flags -c --add-flags "${phpIni}"
        '';
    };

in phpOverride
