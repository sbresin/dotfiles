{
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  wheel,
  lib,
}: let
  pname = "xontrib-prompt-bar";
  version = "0.5.8";
in
  buildPythonPackage {
    inherit pname version;

    src = fetchFromGitHub {
      owner = "anki-code";
      repo = pname;
      rev = version;
      sha256 = "sha256-n80XDApfoUJQORSzIY1FACLeL++HKmIxcz4MAeQ3CZ0=";
    };

    doCheck = false;

    nativeBuildInputs = [
      setuptools
      wheel
    ];

    meta = with lib; {
      homepage = "https://github.com/anki-code/xontrib-prompt-bar";
      license = licenses.bsd2;
      description = "The bar prompt for xonsh shell with customizable sections and Starship support.";
    };
  }
