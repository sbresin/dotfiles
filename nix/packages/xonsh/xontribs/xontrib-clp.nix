{
  buildPythonPackage,
  lib,
  fetchFromGitHub,
  setuptools,
  wheel,
  pyperclip,
  qtpy,
}: let
  pname = "xontrib-clp";
  version = "0.1.7";
in
  buildPythonPackage {
    inherit pname version;

    src = fetchFromGitHub {
      owner = "anki-code";
      repo = pname;
      rev = version;
      sha256 = "sha256-1ewWlwG8KY9s6qydErurvP2x+4DIPTFcjSGP1c5y83M=";
    };

    pyproject = true;
    build-system = [setuptools];

    doCheck = false;

    nativeBuildInputs = [
      setuptools
      wheel
    ];

    propagatedBuildInputs = [
      pyperclip
      qtpy
    ];

    # TODO: remove this if uneeded (setuptools vs poetry)
    prePatch = ''
      sed -ie "/xonsh.*=/d" pyproject.toml
    '';

    meta = with lib; {
      homepage = "https://github.com/anki-code/xontrib-clp";
      description = "Copy output to clipboard (cross-platform) in the [xonsh shell](https://xon.sh).";
      license = licenses.mit;
    };
  }
