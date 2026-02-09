{
  config,
  lib,
  pkgs,
  namespace,
  ...
}: let
  cfg = config.${namespace}.ollama;
in {
  options.${namespace}.ollama = {
    enable = lib.mkEnableOption "ollama LLM server";

    backend = lib.mkOption {
      type = lib.types.enum ["cpu" "rocm" "cuda" "vulkan"];
      default = "cpu";
      description = "Acceleration backend for ollama";
    };

    rocmOverrideGfx = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "11.5.1";
      description = "Override ROCm GPU detection (HSA_OVERRIDE_GFX_VERSION)";
    };
  };

  config = lib.mkIf cfg.enable {
    services.ollama = {
      enable = true;
      package =
        {
          cpu = pkgs.unstable.ollama-cpu;
          rocm = pkgs.unstable.ollama-rocm;
          cuda = pkgs.unstable.ollama-cuda;
          vulkan = pkgs.unstable.ollama-vulkan;
        }
        .${
          cfg.backend
        };
      rocmOverrideGfx = cfg.rocmOverrideGfx;
      environmentVariables = {
        OLLAMA_CONTEXT_LENGTH = "200000";
      };
    };
  };
}
