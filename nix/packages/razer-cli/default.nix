{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  lib,
  # You also have access to your flake's inputs.
  inputs,
  # The namespace used for your flake, defaulting to "internal" if not set.
  namespace,
  # All other arguments come from NixPkgs. You can use `pkgs` to pull packages or helpers
  # programmatically or you may add the named attributes as arguments here.
  pkgs,
  stdenv,
  ...
}:
pkgs.python3Packages.buildPythonApplication rec {
  pname = "razer-cli";
  version = "2.2.1";

  src = pkgs.fetchPypi {
    inherit pname version;
    hash = "sha256-/qT98cGRQd968DGe25hsyjqIwcYbhw77ABUslHGpdEE=";
  };

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
