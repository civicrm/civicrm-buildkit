# Make an own version of php with the new php.ini from above
# add all extensions needed as buildInputs and don't forget to load them in the php.ini above

let
    pkgs = import (import ../../pins/18.03.nix) {
      config = {
        php = {
          mysqlnd = true;
        };
      };
    };

    stdenv = pkgs.stdenv;

    phpRuntime = pkgs.php56;
    phpPkgs = pkgs.php56Packages;
    phpExtras = import ../phpExtras/default.nix {
      pkgs = pkgs;
      php = pkgs.php56; ## Hmm, a little bit loopy, but this effectively how other extensions resolve the loopines..
    };

    phpIniSnippet = ../phpCommon/php.ini;
    phpIni = pkgs.runCommand "php.ini"
    { options = ''
            zend_extension=${phpPkgs.xdebug}/lib/php/extensions/xdebug.so
            extension=${phpPkgs.redis}/lib/php/extensions/redis.so
            extension=${phpPkgs.yaml}/lib/php/extensions/yaml.so
            extension=${phpPkgs.apcu}/lib/php/extensions/apcu.so
            extension=${phpPkgs.memcache}/lib/php/extensions/memcache.so
            extension=${phpPkgs.memcached}/lib/php/extensions/memcached.so
            extension=${phpPkgs.imagick}/lib/php/extensions/imagick.so
            extension=${phpExtras.timecop}/lib/php/extensions/timecop.so
            openssl.cafile=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
      '';
    }
    ''
      cat "${phpRuntime}/etc/php.ini" > $out
      echo "$options" >> $out
      cat "${phpIniSnippet}" >> $out
    '';

    phpOverride = stdenv.mkDerivation rec {
        name = "bknix-php56";
        buildInputs = [phpRuntime phpPkgs.xdebug phpPkgs.redis phpPkgs.yaml phpPkgs.apcu phpPkgs.memcached phpPkgs.memcache phpPkgs.imagick phpExtras.timecop pkgs.makeWrapper pkgs.cacert];
        buildCommand = ''
          makeWrapper ${phpRuntime}/bin/phar $out/bin/phar
          makeWrapper ${phpRuntime}/bin/php $out/bin/php --add-flags -c --add-flags "${phpIni}"
          makeWrapper ${phpRuntime}/bin/php-cgi $out/bin/php-cgi --add-flags -c --add-flags "${phpIni}"
          makeWrapper ${phpRuntime}/bin/php-fpm $out/bin/php-fpm --add-flags -c --add-flags "${phpIni}"
          # makeWrapper ${phpRuntime}/bin/phpdbg $out/bin/phpdbg --add-flags -c --add-flags "${phpIni}"
        '';
        shellHook = ''
          export PATH="$src/bin:$PATH"
        '';
    };

in phpOverride
