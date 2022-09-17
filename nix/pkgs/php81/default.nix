# Make a version of php with extensions and php.ini options

let
    dists = import ../../pins;
    pkgs = dists.v2205;
    phpExtras = import ../phpExtras/default.nix {
      pkgs = pkgs;
      php = pkgs.php81; ## Compile PECL extensions with our preferred version of PHP
    };

    phpIniSnippet1 = builtins.readFile ../phpCommon/php.ini;
    phpIniSnippet2 = ''
      apc.enable_cli = ''${PHP_APC_CLI}
    '';

in pkgs.php81.buildEnv {

  ## EVALUATE: apcu_bc
  extensions = { all, enabled}: with all; enabled++ [ xdebug redis tidy apcu yaml memcached imagick opcache phpExtras.runkit7_4 ];
  extraConfig = phpIniSnippet1 + phpIniSnippet2;

}
