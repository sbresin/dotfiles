{
  buildPythonPackage,
  lib,
  fetchFromGitHub,
  setuptools,
  setuptools-scm,
  poetry-core,
  prompt-toolkit,
  pytestCheckHook,
  xonsh,
}: let
  pname = "xontrib-abbrevs";
  version = "0.1.0";
in
  buildPythonPackage {
    inherit pname version;

    src = fetchFromGitHub {
      owner = "xonsh";
      repo = pname;
      rev = "v${version}";
      hash = "sha256-JxH5b2ey99tvHXSUreU5r6fS8nko4RrS/1c8psNbJNc=";
    };

    format = "pyproject";
    prePatch = ''
      substituteInPlace pyproject.toml \
        --replace '"xonsh>=0.12.5", ' ""
    '';

    nativeBuildInputs = [
      setuptools
      setuptools-scm
      poetry-core
    ];

    propagatedBuildInputs = [
      prompt-toolkit
    ];

    preCheck = ''
      export HOME=$TMPDIR
    '';

    checkInputs = [
      pytestCheckHook
      xonsh
    ];

    meta = with lib; {
      description = "Command abbreviations. This expands input words as you type.";
      homepage = "https://github.com/xonsh/xontrib-abbrevs";
      license = licenses.mit;
      maintainers = [maintainers.greg];
    };
  }
