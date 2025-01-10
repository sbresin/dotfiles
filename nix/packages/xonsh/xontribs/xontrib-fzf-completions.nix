{
  buildPythonPackage,
  lib,
  fetchFromGitHub,
  poetry-core,
  setuptools,
  setuptools-scm,
}: let
  pname = "xontrib-fzf-completions";
  version = "0.0.2";
in
  buildPythonPackage {
    inherit pname version;

    src = fetchFromGitHub {
      owner = "doronz88";
      repo = pname;
      rev = "v${version}";
      hash = "sha256-1z5xHX4Psevn8686QkwIzv/LOJ5IMJc2nQ5Hg/2svTc=";
    };

    format = "pyproject";

    nativeBuildInputs = [
      setuptools
      setuptools-scm
      poetry-core
    ];

    meta = with lib; {
      description = "fzf completions for xonsh";
      homepage = "https://github.com/doronz88/xontrib-fzf-completions";
      license = licenses.gpl3;
      # maintainers = [maintainers.greg];
    };
  }
