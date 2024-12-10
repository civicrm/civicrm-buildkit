rec {
  v1809 = import (import  ./18.09.nix) {};
  v1903 = import (import  ./19.03.nix) {};
  v1909 = import (import  ./19.09.nix) {};
  v2003 = import (import  ./20.03.nix) {};
  v2009 = import (import  ./20.09.nix) {};
  v2105 = import (import  ./21.05.nix) {};
  v2111 = import (import  ./21.11.nix) {};
  v2205 = import (import  ./22.05.nix) {};
  v2305 = import (import  ./23.05.nix) {};
  v2311 = import (import  ./23.11.nix) {};
  v2405 = import (import  ./24.05.nix) {};

  ## Example: If you want to test with your own copy of nixpkgs, then setup your local source-tree:
  ##
  ##   git clone https://EXAMPLE.COM/NIXPKGS.GIT /home/myuser/src/nixpkgs
  ##
  ## And set buildkit to use that:
  #
  # v2405 = import /home/myuser/src/nixpkgs/default.nix {};

  bkit = import ../pkgs;
  default = v2205;
}
