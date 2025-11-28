{pkgs, ...}: {
  pname = "rpi4-uefi-firmware";
  version = "v2025.10.31";
  edk2 = pkgs.fetchFromGitHub {
    owner = "tianocore";
    repo = "edk2";
    name = "edk2";
    rev = "94065db3dc726124b5f607896431e47b36707c90";
    fetchSubmodules = true;
    sha256 = "sha256-PzqLcLeQM9mVdgO7BSsX7WbkYDmmuQ9osiqGiq1gFag=";
  };
  edk2-platforms = pkgs.fetchFromGitHub {
    owner = "tianocore";
    repo = "edk2-platforms";
    name = "edk2-platforms";
    rev = "2cab24f24b49085785cba3fa5ee5ed8b51f95582";
    fetchSubmodules = true;
    sha256 = "sha256-2twzgs/h5goD4qxu3rRP2Mp2d3WmiSr6gpJOb8iz558=";
  };
  edk2-non-osi = pkgs.fetchFromGitHub {
    owner = "tianocore";
    repo = "edk2-non-osi";
    name = "edk2-non-osi";
    rev = "94d048981116e2e3eda52dad1a89958ee404098d";
    sha256 = "sha256-6yuvVvmGn4yaEksbbvGDX1ZcKpdWBKnwaNjLGvgAWyk=";
  };
  rpi-firmware = pkgs.fetchFromGitHub {
    owner = "raspberrypi";
    repo = "firmware";
    name = "rpi-firmware";
    rev = "1.20250915";
    sha256 = "sha256-DqVgsPhppxCsZ+H6S7XY5bBoRhOgPipKibDwikqBk08=";
  };
}
