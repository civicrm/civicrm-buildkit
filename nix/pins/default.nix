rec {
  v1803 = import (import  ./18.03.nix) {};
  v1809 = import (import  ./18.09.nix) {};
  v1903 = import (import  ./19.03.nix) {};
  v1909 = import (import  ./19.09.nix) {};
  v2003 = import (import  ./20.03.nix) {};
  v2009 = import (import  ./20.09.nix) {};
  v2105 = import (import  ./21.05.nix) {};
  v2111 = import (import  ./21.11.nix) {};
  v2205 = import (import  ./22.05.nix) {};
  v2205php82 = import (import  ./22.05-php82.nix) {};

  bkit = import ../pkgs;
  default = v2205;
}
