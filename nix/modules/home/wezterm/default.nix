{pkgs, ...}: let
  wezterm_tabline = pkgs.fetchFromGitHub {
    owner = "michaelbrusegard";
    repo = "tabline.wez";
    rev = "c4c9573bc292a8483a0eab398ef51768d008263b";
    sha256 = "sha256-uZzfia2ybDTckzUk9Sz4yjALQfXtM/CXqxOC9cVZ/gc=";
  };
  wezterm_switcher = pkgs.fetchFromGitHub {
    owner = "MLFlexer";
    repo = "smart_workspace_switcher.wezterm";
    rev = "ef7b5de9280cb8270767cca87385e0a16ed8ead7";
    hash = "sha256-ClhlFTiT0e3gNGid0XomiSMLUJ6FAvE26okoeLNL1C0=";
  };
  wezterm_resurrect = pkgs.fetchFromGitHub {
    owner = "MLFlexer";
    repo = "resurrect.wezterm";
    rev = "8abcbd3345cd95a679d9bd79e4f613f3530c633b";
    hash = "sha256-v8yhkqrjbZAixGDvweKo/uGSkTA+mmGV2isRixmHUfU=";
  };
  wezterm_presentation = pkgs.fetchFromGitLab {
    owner = "xarvex";
    repo = "presentation.wez";
    rev = "55f4bbfe17d3273a2347d6e04903fcecd3f2ee11";
    hash = "sha256-1xcDBjAtXJk2TR+qR1xxsR4WgxA9tqBOsd19nQx8ry8=";
  };
in {
  xdg.configFile."wezterm/plugins.lua".text =
    # lua
    ''
      local M = {}

      local function loadPlugin(plugin_path)
        package.path = package.path .. ';' .. plugin_path .. '/plugin/?.lua'
        return dofile(plugin_path .. '/plugin/init.lua')
      end

      function M.tabline()
        return loadPlugin('${wezterm_tabline}')
      end

      function M.switcher()
        return loadPlugin('${wezterm_switcher}')
      end

      function M.resurrect()
        return loadPlugin('${wezterm_resurrect}')
      end

      function M.presentation()
        return loadPlugin('${wezterm_presentation}')
      end

      return M
    '';
}
