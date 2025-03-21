{
  buildPythonPackage,
  lib,
  fetchFromGitHub,
  setuptools,
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

    #TODO: backtrace is not available in nixpkgs
    propagatedBuildInputs = [
      # backtrace
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
