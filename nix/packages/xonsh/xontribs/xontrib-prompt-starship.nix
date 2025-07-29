{
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  wheel,
  lib,
  starship,
  xonsh,
}: let
  pname = "xontrib-prompt-starship";
  version = "0.3.6";
in
  buildPythonPackage {
    inherit pname version;

    src = fetchFromGitHub {
      owner = "anki-code";
      repo = pname;
      rev = version;
      sha256 = "sha256-CLOvMa3L4XnH53H/k6/1W9URrPakPjbX1T1U43+eSR0=";
    };

    pyproject = true;
    build-system = [setuptools];

    doCheck = false;

    nativeBuildInputs = [
      setuptools
      wheel
      xonsh
    ];

    propagatedBuildInputs = [starship];

    checkInputs = [
      xonsh
    ];

    meta = with lib; {
      homepage = "https://github.com/anki-code/xontrib-sh";
      license = licenses.mit;
      description = "Paste and run commands from bash, fish, zsh, tcsh in the [xonsh shell](https://xon.sh).";
    };
  }
