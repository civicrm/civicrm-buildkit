# Make a version of php with extensions and php.ini options

let
    dists = import ../../pins;
    pkgs = dists.v2505;
    phpExtras = import ../phpExtras/default.nix {
      pkgs = pkgs;
      php = pkgs.php86; ## Compile PECL extensions with our preferred version of PHP
    };

    phpIniSnippet1 = builtins.readFile ../phpCommon/php.ini;
    phpIniSnippet2 = ''
      apc.enable_cli = ''${PHP_APC_CLI}
    '';

in pkgs.php86.buildEnv {

  ## EVALUATE: apcu_bc apcu
  ## TODO: memcached redis xdebug yaml (currently not working during RC)
  extensions = { all, enabled }: with all; enabled++ [ tidy imagick opcache ];
  extraConfig = phpIniSnippet1 + phpIniSnippet2;

}
