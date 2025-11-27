{
  inputs,
  pkgs,
  ...
}: {
  containers.pi-hole = {
    autoStart = true;
    ephemeral = true;
    macvlans = ["eth0"];
    privateNetwork = true;
    #extraFlags = ["-U"]; # private user namespace
    config = {...}: {
      nixpkgs.pkgs = pkgs; # use host packages
      networking = {
        hostName = "pi-hole";
        useDHCP = false;
        useNetworkd = true;
        useHostResolvConf = false;
        firewall.enable = true;
      };
      systemd.network = {
        enable = true;
        networks = {
          "40-mv-eth0" = {
            matchConfig.Name = "mv-eth0";
            linkConfig.RequiredForOnline = "routable";
            address = [
              "192.168.178.3/24"
            ];
            networkConfig.DHCP = "no";
            # dhcpV4Config.ClientIdentifier = "mac";
          };
        };
      };

      imports = [
        "${inputs.nixpkgs-unstable}/nixos/modules/services/networking/pihole-ftl.nix"
        "${inputs.nixpkgs-unstable}/nixos/modules/services/web-apps/pihole-web.nix"
      ];
      services.pihole-ftl = {
        enable = true;
        package = pkgs.unstable.pihole-ftl;
        piholePackage = pkgs.unstable.pihole;
        openFirewallWebserver = true;
        openFirewallDNS = true;
        openFirewallDHCP = false;
      };

      services.pihole-web = {
        enable = true;
        package = pkgs.unstable.pihole-web;
        ports = [
          "80r"
          "443s"
        ];
      };

      system.stateVersion = "25.05";
    };
  };
}
