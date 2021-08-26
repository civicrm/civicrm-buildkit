# Make a version of php with extensions and php.ini options

let
    pkgs = import (import ../../pins/pre-21.05.nix) {};
    ## TEST ME: Do we need to set config.php.mysqlnd = true?

    phpExtras = import ../phpExtras/default.nix {
      pkgs = pkgs;
      php = pkgs.php80; ## Compile PECL extensions with our preferred version of PHP
    };

    phpIniSnippet1 = builtins.readFile ./php.ini;
    phpIniSnippet2 = ''
      apc.enable_cli = ''${PHP_APC_CLI}
    '';

in pkgs.php80.buildEnv {

  ## EVALUATE: apcu_bc
  extensions = { all, enabled}: with all; enabled++ [ xdebug redis tidy apcu yaml memcached imagick opcache phpExtras.runkit7_4 ];
  extraConfig = phpIniSnippet1 + phpIniSnippet2;

}
