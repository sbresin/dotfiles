{
  buildPythonPackage,
  lib,
  fetchFromGitHub,
  setuptools,
  colorama,
  # backtrace,
}: let
  pname = "xontrib-readable-traceback";
  version = "0.4.0";
in
  buildPythonPackage {
    inherit pname version;

    src = fetchFromGitHub {
      owner = "vaaaaanquish";
      repo = pname;
      rev = version;
      hash = "sha256-ek+GTWGUpm2b6lBw/7n4W46W2R0Gy6JxqWoLuQilCXQ=";
    };

    pyproject = true;
    build-system = [setuptools];

    doCheck = false;

    #TODO: backtrace is not available in nixpkgs
    propagatedBuildInputs = [
      # backtrace
      colorama
    ];

    nativeBuildInputs = [
      setuptools
    ];

    meta = with lib; {
      description = "Make traceback easier to see for xonsh.";
      homepage = "https://github.com/vaaaaanquish/xontrib-readable-traceback";
      license = licenses.mit;
    };
  }
