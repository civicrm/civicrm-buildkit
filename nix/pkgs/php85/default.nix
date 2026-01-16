# Make a version of php with extensions and php.ini options

let
    dists = import ../../pins;
    pkgs = dists.v2505;
    phpExtras = import ../phpExtras/default.nix {
      pkgs = pkgs;
      php = pkgs.php85; ## Compile PECL extensions with our preferred version of PHP
    };

    phpIniSnippet1 = builtins.readFile ../phpCommon/php.ini;
    phpIniSnippet2 = ''
      apc.enable_cli = ''${PHP_APC_CLI}
    '';

in pkgs.php85.buildEnv {

  ## EVALUATE: apcu_bc apcu phpExtras.xdebug34
  extensions = { all, enabled }: with all; enabled++ [ tidy yaml memcached imagick opcache redis ];
  extraConfig = phpIniSnippet1 + phpIniSnippet2;

}
