{
  lib,
  pkgs,
  ...
}:
pkgs.python3Packages.buildPythonApplication rec {
  pname = "razer-cli";
  version = "2.3.0";

  src = pkgs.fetchPypi {
    pname = "razer_cli";
    inherit version;
    hash = "sha256-BvNumOvyNYqEnbhBZ/zdcQwF4+8kMGYE6X1QZwHil9g=";
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
