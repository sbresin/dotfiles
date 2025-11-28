{
  pkgs,
  acpica-tools,
  python3,
  lib,
  ...
}: let
  sources = pkgs.callPackage ./sources.nix {};
  edk2_base_tools = pkgs.callPackage ./basetools.nix {};
  crossPkgs = pkgs.pkgsCross.aarch64-multiplatform;
in
  crossPkgs.stdenv.mkDerivation {
    inherit (sources) pname version;

    srcs = [
      edk2_base_tools
      sources.edk2-platforms
      sources.edk2-non-osi
      sources.rpi-firmware
      (lib.fileset.toSource
        {
          root = ./.;
          fileset = ./config.txt;
        })
    ];
    sourceRoot = ".";

    patches = [
      # limit only needed for XHCI, which compute module doesn't have
      ./patches/RamMoreThan3GB_default.patch
      # needed for pcie support
      ./patches/SystemTableMode_devicetree.patch
    ];

    nativeBuildInputs = [python3 acpica-tools];

    dontConfigure = true;
    hardeningDisable = ["format"];
    buildPhase = ''
      runHook preBuild

      export WORKSPACE="$PWD"
      export PACKAGES_PATH=$PWD/edk2:$PWD/edk2-platforms:$PWD/edk2-non-osi

      source edk2/edksetup.sh BaseTools

      export GCC5_AARCH64_PREFIX=aarch64-unknown-linux-gnu-

      build -a AARCH64 -t GCC5 -b RELEASE \
        -p Platform/RaspberryPi/RPi4/RPi4.dsc \
        --pcd gEfiMdeModulePkgTokenSpaceGuid.PcdFirmwareVendor=L"sbresin" \
        --pcd gEfiMdeModulePkgTokenSpaceGuid.PcdFirmwareVersionString=L"UEFI Firmware ${sources.version}" \
        -D SECURE_BOOT_ENABLE=TRUE -D INCLUDE_TFTP_COMMAND=TRUE -D NETWORK_ISCSI_ENABLE=TRUE -D SMC_PCI_SUPPORT=1

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp Build/RPi4/RELEASE_GCC5/FV/RPI_EFI.fd $out

      cp rpi-firmware/boot/fixup4.dat $out
      cp rpi-firmware/boot/start4.elf $out
      cp rpi-firmware/boot/bcm2711-rpi-4-b.dtb $out
      cp rpi-firmware/boot/bcm2711-rpi-cm4.dtb $out
      cp rpi-firmware/boot/bcm2711-rpi-400.dtb $out
      cp -R rpi-firmware/boot/overlays $out
      cp source/config.txt $out

      runHook postInstall
    '';

    dontFixup = true;
  }
