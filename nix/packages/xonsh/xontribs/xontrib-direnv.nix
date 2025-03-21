{
  buildPythonPackage,
  lib,
  fetchFromGitHub,
  direnv,
  setuptools,
}: let
  pname = "xonsh-direnv";
  version = "1.6.5";
in
  buildPythonPackage {
    inherit pname version;

    src = fetchFromGitHub {
      owner = "74th";
      repo = pname;
      rev = version;
      hash = "sha256-huBJ7WknVCk+WgZaXHlL+Y1sqsn6TYqMP29/fsUPSyU=";
    };

    propagatedBuildInputs = [
      direnv
    ];

    nativeBuildInputs = [
      setuptools
    ];

    meta = with lib; {
      description = "Direnv support for Xonsh";
      homepage = "https://github.com/74th/xonsh-direnv/";
      license = licenses.mit;
    };
  }
