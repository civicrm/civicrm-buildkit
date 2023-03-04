with (import ../../pins).default;

buildGoModule rec {
  pname = "transifex-cli";
  version = "1.6.5";

  src = fetchFromGitHub {
    owner = "transifex";
    repo = "cli";
    rev = "v${version}";
    sha256 = "76mGMf70MD3aLgMCNqVyjrx8Rx5aIT+vYQGsPYjEM28=";
  };

  vendorSha256 = "rcimaHr3fFeHSjZXw1w23cKISCT+9t8SgtPnY/uYGAU=";
  postBuild = ''
    mv $GOPATH/bin/cli $GOPATH/bin/tx
  '';
  doCheck = false;

  ## subPackages = [ "cmd" ]; ## random copy-paste, no idea what this is for

  meta = with lib; {
    description = "Transifex CLI";
    homepage = "https://github.com/transifex/transifex-cli";
    license = licenses.asl20;
  };
}
