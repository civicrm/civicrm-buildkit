/**
 * MySQL 8.0.22 backport circa Jan 2021
 *
 * See: https://github.com/NixOS/nixpkgs/pull/109006
 * See: https://github.com/totten/nixpkgs/commits/master-mysql-8022
 */
fetchTarball {
  url = "https://github.com/totten/nixpkgs/archive/0f387ba1841386c3a503bc1ddeb40658d7d907d5.tar.gz";
  sha256 = "03ilqnz71546na5m07v0swxz45q8mj7x92r7y3lr29p65nqdry0c";
}
