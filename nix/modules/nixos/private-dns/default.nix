{
  config,
  lib,
  namespace,
  pkgs,
  ...
}: let
  cfg = config.${namespace}.private-dns;
  dnscrypt-forwarding = pkgs.writeTextFile {
    name = "forwarding-rules.txt";
    text = ''
      fritz.box        192.168.178.1
      192.in-addr.arpa 192.168.178.1
    '';
  };
in {
  options.${namespace}.private-dns = {
    enable = lib.mkEnableOption "setup dnscrypt proxy";
  };

  config = lib.mkIf cfg.enable {
    networking = {
      # don't globally enforce nameservers, configure per network through nnetworkmanager
      nameservers = lib.mkForce [];
    };

    services.dnscrypt-proxy2 = {
      enable = true;
      settings = {
        forwarding_rules = "${dnscrypt-forwarding}";
        block_undelegated = false;
        ipv6_servers = true;
        require_dnssec = true;

        sources.public-resolvers = {
          urls = [
            "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md"
            "https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
          ];
          cache_file = "/var/lib/dnscrypt-proxy/public-resolvers.md";
          minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
        };

        # You can choose a specific set of servers from https://github.com/DNSCrypt/dnscrypt-resolvers/blob/master/v3/public-resolvers.md
        server_names = ["cloudflare-security"];

        query_log = {
          file = "/var/log/dnscrypt-proxy/query.log";
          format = "tsv";
          ignored_qtypes = ["DNSKEY" "NS"];
        };
      };
    };
  };
}
