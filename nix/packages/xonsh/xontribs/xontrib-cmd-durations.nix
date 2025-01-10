{
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  wheel,
  poetry-core,
  pdm-pep517,
  lib,
  notify-py,
  xdotool,
}: let
  pname = "xontrib-cmd-durations";
  version = "0.3.2";
in
  buildPythonPackage {
    inherit pname version;

    src = fetchFromGitHub {
      owner = "jnoortheen";
      repo = pname;
      rev = "v${version}";
      sha256 = "sha256-qFIjXBLyNqGnrslMvhqKpTvJDT79yWdHkDvS6JebVUk=";
    };

    doCheck = false;

    nativeBuildInputs = [
      setuptools
      wheel
      poetry-core
    ];

    propagatedBuildInputs = [notify-py xdotool];

    format = "pyproject";

    build-system = [
      setuptools
      pdm-pep517
      poetry-core
    ];

    postPatch = ''
      sed -ie "/xonsh.*=/d" pyproject.toml
    '';

    meta = with lib; {
      homepage = "https://github.com/jnoortheen/xontrib-cmd-durations";
      license = licenses.mit;
      # maintainers = [maintainers.drmikecrowe];
      description = "Show long running commands durations in prompt with option to send notification when terminal is not focused.";
    };
  }
