# Make a version of php with extensions and php.ini options

let
    dists = import ../../pins;
    pkgs = dists.v2205;
    phpExtras = import ../phpExtras/default.nix {
      pkgs = pkgs;
      php = pkgs.php74; ## Compile PECL extensions with our preferred version of PHP
    };

    phpIniSnippet1 = builtins.readFile ../phpCommon/php.ini;
    phpIniSnippet2 = ''
      apc.enable_cli = ''${PHP_APC_CLI}
    '';

in pkgs.php74.buildEnv {

  ## EVALUATE: apcu_bc
  extensions = { all, enabled}: with all; enabled++ [ xdebug redis tidy apcu apcu_bc yaml memcached imagick opcache phpExtras.runkit7_3 phpExtras.timecop ];
  extraConfig = phpIniSnippet1 + phpIniSnippet2;

}
