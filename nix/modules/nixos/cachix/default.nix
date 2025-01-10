{...}: {
  nix.settings = {
    trusted-users = ["sebe"];

    # the system-level substituters & trusted-public-keys
    substituters = [
      "https://cache.nixos.org"
    ];

    # trusted-public-keys = [
    #   # the default public key of cache.nixos.org, it's built-in, no need to add it here
    #   "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    # ];
  };
}
