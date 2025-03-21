{
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  wheel,
  lib,
}: let
  pname = "xontrib-sh";
  version = "0.3.1";
in
  buildPythonPackage {
    inherit pname version;

    src = fetchFromGitHub {
      owner = "anki-code";
      repo = pname;
      rev = version;
      sha256 = "sha256-KL/AxcsvjxqxvjDlf1axitgME3T+iyuW6OFb1foRzN8=";
    };

    doCheck = false;

    nativeBuildInputs = [
      setuptools
      wheel
    ];

    meta = with lib; {
      homepage = "https://github.com/anki-code/xontrib-sh";
      license = licenses.mit;
      description = "Paste and run commands from bash, fish, zsh, tcsh in the [xonsh shell](https://xon.sh).";
    };
  }
