{ config, pkgs, ... }:

{
  config = {
    news.display = "silent";
    news.json = pkgs.lib.mkForce { };
    news.entries = pkgs.lib.mkForce [ ];
  };
}
