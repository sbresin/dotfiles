{
  buildPythonPackage,
  lib,
  fetchFromGitHub,
  poetry-core,
  setuptools,
  wheel,
}: let
  pname = "xontrib-vox";
  version = "0.0.1";
in
  buildPythonPackage {
    inherit pname version;

    src = fetchFromGitHub {
      owner = "xonsh";
      repo = pname;
      rev = version;
      hash = "sha256-OB1O5GZYkg7Ucaqak3MncnQWXhMD4BM4wXsYCDD0mhk=";
    };

    format = "pyproject";

    prePatch = ''
      sed -ie "/xonsh.*=/d" pyproject.toml
    '';

    nativeBuildInputs = [
      setuptools
      wheel
      poetry-core
    ];

    doCheck = false;

    meta = with lib; {
      description = "Python virtual environment manager for xonsh.";
      homepage = "https://github.com/xonsh/xontrib-vox";
      license = licenses.mit;
      # maintainers = [maintainers.greg];
    };
  }
