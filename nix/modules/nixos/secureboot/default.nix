{
  config,
  lib,
  pkgs,

  ...
}:
let
  cfg = config.sebe.secureboot;
in
{
  options.sebe.secureboot = {
    enable = lib.mkEnableOption "setup secureboot";
  };

  config = lib.mkIf cfg.enable {
    # lanzaboote replaces systemd-boot
    boot.loader.systemd-boot.enable = lib.mkForce false;

    boot.lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };

    # for TPM based LUKS decryption we need systemd
    boot.initrd.systemd.enable = true;

    # Linux 7.0 removed the standalone aes_generic module — it's now just "aes".
    # NixOS luksroot.nix still defaults to including aes_generic which breaks
    # module-closure builds for kernels >= 7.0.
    # Upstream fix: https://github.com/NixOS/nixpkgs/commit/ae8b3f7d554d
    # TODO: remove this override once our nixpkgs pin includes that commit.
    boot.initrd.luks.cryptoModules = [
      "aes"
      "blowfish"
      "twofish"
      "serpent"
      "cbc"
      "xts"
      "lrw"
      "sha1"
      "sha256"
      "sha512"
      "af_alg"
      "algif_skcipher"
      "cryptd"
      "input_leds"
    ];

    environment.systemPackages = with pkgs.unstable; [
      sbctl
      sbsigntool
    ];
  };
}
