{
  buildPythonPackage,
  lib,
  fetchFromGitHub,
  setuptools,
}: let
  pname = "xontrib-argcomplete";
  version = "0.3.3";
in
  buildPythonPackage {
    inherit pname version;

    src = fetchFromGitHub {
      owner = "anki-code";
      repo = pname;
      rev = version;
      hash = "sha256-4tw5nnwmETu+iGvNxC9FUZ0h6Pu7W3dxSMxIGSBRlxg=";
    };

    nativeBuildInputs = [
      setuptools
    ];

    meta = with lib; {
      description = "Argcomplete support to tab completion of python and xonsh scripts in xonsh shell.";
      homepage = "https://github.com/anki-code/xontrib-argcomplete";
      license = licenses.mit;
    };
  }
