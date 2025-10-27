{pkgs, ...}: {
  # use Lix fork (faster and community driven)
  # nix dependend packages set through overlay
  nix.package = pkgs.lixPackageSets.latest.lix;

  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    trusted-users = ["sebe"];

    # the system-level substituters & trusted-public-keys
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "wezterm.cachix.org-1:kAbhjYUC9qvblTE+s7S+kl5XM1zVa4skO+E/1IDWdH0="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://wezterm.cachix.org"
      "https://hyprland.cachix.org"
    ];
  };

  # Use nh nix cli wrapper
  programs.nh.enable = true;

  environment.systemPackages = with pkgs.unstable; [
    git
    nix-output-monitor
  ];
}
