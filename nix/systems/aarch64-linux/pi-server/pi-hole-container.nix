{...}: {
  containers.pi-hole = {
    autoStart = true;
    ephemeral = true;
    macvlans = ["eth0"];
    privateNetwork = true;
    #extraFlags = ["-U"]; # private user namespace
    config = {pkgs, ...}: {
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
    };
  };
}
