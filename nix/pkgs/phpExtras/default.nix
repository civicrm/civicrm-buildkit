/**
 * phpExtras is a library of supplemental PECL extensions. These extensions
 * aren't defined in <nixpkgs>
 */

{ pkgs, php}:

let

  buildPecl = import ./build-pecl.nix {
    php = php.unwrapped;
    inherit (pkgs) lib;
    inherit (pkgs) stdenv autoreconfHook fetchurl re2c;
  };

in rec {

  timecop = buildPecl {
    pname = "timecop";
    version = "1.2.10";
    sha256 = "1c74k2dmpi9naipsnagrqcaxii2h82m2mhdrxgdalrshgkpv0vdh";
    configureFlags = [ ];
    nativeBuildInputs = [ pkgs.pkg-config ];
    buildInputs = [ ];
  };

  ## runkit7 v4.x: Only series to support PHP 8
  runkit7_4 = buildPecl {
    pname = "runkit7";
    version = "4.0.0a6";
    sha256 = "28ldfLgy4WBMyr85VjT2GG1DGDJ19j8OgmNVL2kdDNg=";
    configureFlags = [ ];
    nativeBuildInputs = [ pkgs.pkg-config ];
    buildInputs = [ ];
  };

  ## runkit7 v3.x: Only series to support PHP 7.4 (pending in v3.1...)
  runkit7_3 = buildPecl {
    pname = "runkit7";
    version = "3.1.0a1";
    src = pkgs.fetchurl {
      url = "https://github.com/runkit7/runkit7/releases/download/3.1.0a1/runkit7-3.1.0a1.tgz";
      sha256 = "1p9g8xk0n78ygbr0n0pzg1vr075y43y6hjhgzsc2a4530m8vx4ac";
    };
    configureFlags = [ ];
    nativeBuildInputs = [ pkgs.pkg-config ];
    buildInputs = [ ];
  };

  ## runkit7 v2.x: Bridge, supporting old+new APIs, but only supports PHP 7.1-7.3
  runkit7_2 = buildPecl {
    pname = "runkit7";
    version = "2.1.0";
    sha256 = "1pdhabxqnwlxgbayw9clzlfk6qbh9wfa31gsd5f9nfhz2ym4wr34";
    configureFlags = [ ];
    nativeBuildInputs = [ pkgs.pkg-config ];
    buildInputs = [ ];
  };

  ## The runkit7 v1.x: Only version to support PHP 7.0.
  runkit7_1 = buildPecl {
    pname = "runkit7";
    version = "1.0.11";
    src = pkgs.fetchurl {
      url = "https://github.com/runkit7/runkit7/releases/download/1.0.11/runkit-1.0.11.tgz";
      sha256 = "056v6h8cscqbkdxs9lr33j0x8255k4k3yqlnylvkwl4daavxwlfp";
    };
    configureFlags = [ ];
    nativeBuildInputs = [ pkgs.pkg-config ];
    buildInputs = [ ];
  };

  xdebug2 = buildPecl {
    version = "2.8.1";
    pname = "xdebug";
    sha256 = "080mwr7m72rf0jsig5074dgq2n86hhs7rdbfg6yvnm959sby72w3";
    doCheck = true;
    checkTarget = "test";
    zendExtension = true;
  };

  xdebug3 = buildPecl {
    ## XDebug 3.1 supports php72, php73, php74, php80, php81 (https://xdebug.org/docs/compat)
    version = "3.1.6";
    pname = "xdebug";
    sha256 = "VU7KC01be5PLIlj6sLC9hMyHIedDIqIlXBThN8vK1dI=";
    doCheck = true;
    checkTarget = "test";
    zendExtension = true;
  };

  xdebug32 = buildPecl {
    ## XDebug 3.2 supports php80, php81, php82 (https://xdebug.org/docs/compat)
    version = "3.2.2";
    pname = "xdebug";
    sha256 = "9Id3Nx+Qy7MV6k6ggqHt5nZbz7NdfWNWq49x/W38wVc=";
    doCheck = true;
    checkTarget = "test";
    zendExtension = true;
  };

  xdebug33 = buildPecl {
    ## XDebug 3.3 supports php80, php81, php82, php83 (https://xdebug.org/docs/compat)
    version = "3.3.1";
    pname = "xdebug";
    sha256 = "TrTuJwu8xfFBlcOPbuWFgOAHz0iGzjLhFDAxirW8IxU=";
    doCheck = true;
    checkTarget = "test";
    zendExtension = true;
  };

  xdebug34 = buildPecl {
    ## XDebug 3.4 supports php81, php82, php83, php84 (https://xdebug.org/docs/compat)
    version = "3.4.0";
    pname = "xdebug";
    src = pkgs.fetchurl {
      url = "https://xdebug.org/files/xdebug-3.4.0.tgz";
      sha256 = "sha256-iWZ7jQSq8EwCPrEJkA4czpfKOfl/Lz8kGZYwzA4cx30";
    };
    doCheck = true;
    checkTarget = "test";
    zendExtension = true;
  };

}
