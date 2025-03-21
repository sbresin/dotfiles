{
  lib,
  python3Packages,
  fetchFromGitHub,
  chntpw,
}:
python3Packages.buildPythonApplication {
  pname = "bt-dualboot";
  version = "1.0.1-bc8c949";

  src = fetchFromGitHub {
    owner = "Simon128";
    repo = "bt-dualboot";
    rev = "bc8c949bea93ab7d0c4dc763a866e8531b4d95fa";
    hash = "sha256-WzN2ki3VHrScSVpAn+JVX2AUNfG6g7fy4+1LDAtso9k=";
  };

  format = "pyproject";

  nativeBuildInputs = with python3Packages; [
    setuptools
    wheel
    poetry-core
  ];

  propagatedBuildInputs = [
    chntpw
  ];

  # doCheck = false;

  meta = with lib; {
    description = "Sync Bluetooth for dualboot Linux and Windows";
    mainProgram = "bt-dualboot";
    homepage = "https://github.com/Simon128/bt-dualboot";
    license = licenses.mit;
  };
}
