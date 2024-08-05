# Make a version of php with extensions and php.ini options

let
    dists = import ../../pins;
    pkgs = dists.v2405;
    phpExtras = import ../phpExtras/default.nix {
      pkgs = pkgs;
      php = pkgs.php84; ## Compile PECL extensions with our preferred version of PHP
    };

    phpIniSnippet1 = builtins.readFile ../phpCommon/php.ini;
    phpIniSnippet2 = ''
      apc.enable_cli = ''${PHP_APC_CLI}
    '';

in pkgs.php84.buildEnv {

  ## EVALUATE: apcu_bc
  ## TODO: imap redis phpExtras.runkit7_4
  extensions = { all, enabled }: with all; enabled++ [ phpExtras.xdebug34 tidy yaml memcached imagick opcache apcu ];
  extraConfig = phpIniSnippet1 + phpIniSnippet2;

}
