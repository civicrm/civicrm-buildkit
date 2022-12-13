# Make a version of php with extensions and php.ini options

let
    dists = import ../../pins;
    pkgs = dists.v2205php82;
    phpExtras = import ../phpExtras/default.nix {
      pkgs = pkgs;
      php = pkgs.php82; ## Compile PECL extensions with our preferred version of PHP
    };

    phpIniSnippet1 = builtins.readFile ../phpCommon/php.ini;
    phpIniSnippet2 = ''
    '';
    ## TODO(phpIniSnippet2):  apc.enable_cli = ''${PHP_APC_CLI}

in pkgs.php82.buildEnv {

  ## TODO: apcu_bc tidy
  extensions = { all, enabled }: with all; enabled++ [ apcu imagick memcached opcache redis yaml phpExtras.xdebug32 phpExtras.runkit7_4 ];
  extraConfig = phpIniSnippet1 + phpIniSnippet2;

}
