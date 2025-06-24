rec {
  v2105 = import (import  ./21.05.nix) {};
  v2205 = import (import  ./22.05.nix) {};
  v2405 = import (import  ./24.05.nix) {};
  v2505 = import (import  ./25.05.nix) {};

  ## Example: If you want to test with your own copy of nixpkgs, then setup your local source-tree:
  ##
  ##   git clone https://EXAMPLE.COM/NIXPKGS.GIT $HOME/src/nixpkgs
  ##
  ## And set buildkit to use that, as in:
  #
  # v2405 = import /home/myuser/src/nixpkgs/default.nix {};
  # v2405 = import ((builtins.getEnv "HOME") + "/src/nixpkgs/default.nix") {};

  bkit = import ../pkgs;
  default = v2505;
}
