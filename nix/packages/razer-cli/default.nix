{
  lib,
  pkgs,
  ...
}:
pkgs.python3Packages.buildPythonApplication rec {
  pname = "razer-cli";
  version = "2.2.1";

  src = pkgs.fetchPypi {
    inherit pname version;
    hash = "sha256-/qT98cGRQd968DGe25hsyjqIwcYbhw77ABUslHGpdEE=";
  };

  pyproject = true;
  build-system = with pkgs.python3Packages; [
    setuptools
  ];

  dependencies = with pkgs; [
    python3Packages.openrazer
    xorg.xrdb
  ];

  # rename to avoid conflict with razer-laptop-config
  postInstall = ''
    mv $out/bin/razer-cli $out/bin/openrazer-cli
  '';

  meta = with lib; {
    description = "Command line interface for controlling Razer devices on Linux";
    homepage = "https://github.com/lolei/razer-cli";
    license = licenses.gpl3;
    maintainers = [];
  };
}
