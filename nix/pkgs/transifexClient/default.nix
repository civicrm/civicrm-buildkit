{ goPackages, lib, fetchFromGitHub, six, requests }:
buildGoModule rec {
  pname = "transifex-cli";
  version = "1.6.5";

  src = fetchFromGitHub {
    owner = "transifex";
    repo = "transifex-cli";
    rev = "${version}";
    sha256 = "FIXME";
  };

  modSha256 = "FIXME";

  ## subPackages = [ "cmd" ]; ## random copy-paste, no idea what this is for

  meta = with stdenv.lib; {
    description = "Transifex CLI";
    homepage = "https://github.com/transifex/transifex-cli";
    license = licenses.asl20;
  };
}
