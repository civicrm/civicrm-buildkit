{ lib, python, fetchFromGitHub, python-slugify, six, requests }:
with python.pkgs;
buildPythonApplication rec {
  pname = "transifex-client";
  version = "0.13.9";

  propagatedBuildInputs = [
    urllib3 requests python-slugify six setuptools
  ];

  src = fetchPypi {
    inherit pname version;
    sha256 = "0lgd77vrddvyn8afkxr7a7hblmp4k5sr0i9i1032xdih2bipdd9f";
  };

  prePatch = ''
    substituteInPlace requirements.txt --replace "urllib3<1.24" "urllib3>=1.24" \
      --replace "six==1.11.0" "six>=1.11.0" \
      --replace "python-slugify<2.0.0" "python-slugify>2.0.0"
  '';

  doCheck = false;


  meta = {
    homepage = https://github.com/transifex/transifex-client;
    description = "Transifex CLI Client";
    license = lib.licenses.bsd2;
  };
}
