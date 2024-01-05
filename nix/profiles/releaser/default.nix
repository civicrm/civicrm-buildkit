/**
 * The `releaser` profile can be used if you just need to run the `releaser.php` script.
 * It doesn't need full dev environment (no daemons / no fpm / no mysqld / etc).
 */
let
    dists = import ../../pins;
    stdenv = dists.default.stdenv;
    ## Some older packages aren't buildable on Apple M1, so we use closest match.
    isAppleM1 = stdenv.isDarwin && stdenv.isAarch64;

in (import ../base/default.nix) ++ (import ../mgmt/default.nix) ++ [

    dists.bkit.php81
    # dists.default.nodejs-16_x
    # (if isAppleM1 then dists.default.mysql80 else dists.default.mysql57)
    dists.v2305.google-cloud-sdk

]
