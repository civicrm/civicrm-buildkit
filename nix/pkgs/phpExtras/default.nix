/**
 * phpExtras is a library of supplemental PECL extensions. These extensions
 * aren't defined in <nixpkgs>
 */

{ pkgs, php }:

let

  buildPecl = import ./build-pecl.nix {
    inherit php;
    inherit (pkgs) stdenv autoreconfHook fetchurl;
  };

in rec {

  timecop = buildPecl {
    name = "timecop-1.2.10";
    sha256 = "1c74k2dmpi9naipsnagrqcaxii2h82m2mhdrxgdalrshgkpv0vdh";
    configureFlags = [ ];
    nativeBuildInputs = [ pkgs.pkgconfig ];
    buildInputs = [ ];
  };

  ## runkit7 v3.x: Only series to support PHP 7.4 (pending in v3.1...)
  runkit7_3 = buildPecl {
    name = "runkit7-3.1.0a1";
    src = pkgs.fetchurl {
      url = "https://github.com/runkit7/runkit7/releases/download/3.1.0a1/runkit7-3.1.0a1.tgz";
      sha256 = "1p9g8xk0n78ygbr0n0pzg1vr075y43y6hjhgzsc2a4530m8vx4ac";
    };
    configureFlags = [ ];
    nativeBuildInputs = [ pkgs.pkgconfig ];
    buildInputs = [ ];
  };

  ## runkit7 v2.x: Bridge, supporting old+new APIs, but only supports PHP 7.1-7.3
  runkit7_2 = buildPecl {
    name = "runkit7-2.1.0";
    sha256 = "1pdhabxqnwlxgbayw9clzlfk6qbh9wfa31gsd5f9nfhz2ym4wr34";
    configureFlags = [ ];
    nativeBuildInputs = [ pkgs.pkgconfig ];
    buildInputs = [ ];
  };

  ## The runkit7 v1.x: Only version to support PHP 7.0.
  runkit7_1 = buildPecl {
    name = "runkit7-1.0.11";
    src = pkgs.fetchurl {
      url = "https://github.com/runkit7/runkit7/releases/download/1.0.11/runkit-1.0.11.tgz";
      sha256 = "056v6h8cscqbkdxs9lr33j0x8255k4k3yqlnylvkwl4daavxwlfp";
    };
    configureFlags = [ ];
    nativeBuildInputs = [ pkgs.pkgconfig ];
    buildInputs = [ ];
  };

  inotify = buildPecl {
    name = "inotify-2.0.0";
    sha256 = "01si0jn4jzkxhcywzflnh1v0ksxm5b4v30pi6h7i3amv4sfshi6h";
    configureFlags = [ ];
    nativeBuildInputs = [ pkgs.pkgconfig ];
    buildInputs = [ ];
#    https://pecl.php.net/get/inotify-2.0.0.tgz
  };

  inotify_0 = buildPecl {
    name = "inotify-0.1.6";
    sha256 = "0kj9bcp9jj1yjjdhnc9z72l4cwzh8vgw1zqp4qldxc2fbni817wp";
    configureFlags = [ ];
    nativeBuildInputs = [ pkgs.pkgconfig ];
    buildInputs = [ ];
  };

}
