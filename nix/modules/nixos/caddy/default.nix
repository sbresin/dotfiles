{
  config,
  lib,
  pkgs,
  namespace,
  ...
}: let
  cfg = config.${namespace}.caddy;
in {
  options.${namespace}.caddy = {
    enable = lib.mkEnableOption "caddy reverse proxy for local services";

    services = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          port = lib.mkOption {
            type = lib.types.port;
            description = "Port the service listens on";
          };
          host = lib.mkOption {
            type = lib.types.str;
            default = "127.0.0.1";
            description = "Host the service listens on";
          };
        };
      });
      default = {};
      description = "Services to reverse proxy (name becomes <name>.localhost)";
      example = {
        ollama = {port = 11434;};
        searxng = {port = 8080;};
        openwebui = {port = 3000;};
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.caddy = {
      enable = true;
      package = pkgs.unstable.caddy;
      # Create separate HTTP and HTTPS virtualHosts for each service.
      # HTTP (http://<name>.localhost) allows unencrypted access without cert warnings.
      # HTTPS (<name>.localhost) uses Caddy's internal CA for encrypted local traffic.
      virtualHosts = let
        httpsHosts = lib.mapAttrs' (name: svc: {
          name = "${name}.localhost";
          value = {
            extraConfig = ''
              tls internal
              reverse_proxy ${svc.host}:${toString svc.port}
            '';
          };
        }) cfg.services;

        httpHosts = lib.mapAttrs' (name: svc: {
          name = "http://${name}.localhost";
          value = {
            extraConfig = ''
              reverse_proxy ${svc.host}:${toString svc.port}
            '';
          };
        }) cfg.services;
      in
        httpsHosts // httpHosts;
    };

    # Add /etc/hosts entries for all .localhost domains
    networking.hosts."127.0.0.1" =
      map (name: "${name}.localhost") (lib.attrNames cfg.services);
  };
}
