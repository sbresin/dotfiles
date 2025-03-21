{
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  wheel,
  poetry-core,
  pdm-pep517,
  lib,
}: let
  pname = "xontrib-term-integrations";
  version = "0.2.0-ef8b2e5";
in
  buildPythonPackage {
    inherit pname version;

    src = fetchFromGitHub {
      owner = "jnoortheen";
      repo = pname;
      rev = "ef8b2e58cc67ec50ed1d42ffe385517b3d6b6cee";
      sha256 = "sha256-+0v7at3Muvkf7UolPL1AufKXIKyAOJlF6y7HurOckik=";
    };

    doCheck = false;

    nativeBuildInputs = [
      setuptools
      wheel
      poetry-core
    ];

    format = "pyproject";

    build-system = [
      setuptools
      pdm-pep517
      poetry-core
    ];

    postPatch = ''
      substituteInPlace pyproject.toml \
      --replace poetry.masonry.api poetry.core.masonry.api \
      --replace "poetry>=" "poetry-core>="
      sed -ie "/xonsh.*=/d" pyproject.toml
    '';

    meta = with lib; {
      homepage = "https://github.com/jnoortheen/xontrib-term-integrations";
      license = licenses.mit;
      description = "Support shell integration of terminal programs iTerm2, Kitty, etc in the [xonsh shell](https://xon.sh).";
    };
  }
