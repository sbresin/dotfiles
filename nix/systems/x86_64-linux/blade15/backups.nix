{...}: {
  services.snapper = {
    persistentTimer = true;
    configs = {
      home = {
        SUBVOLUME = "/home";
        ALLOW_USERS = ["sebe"];
        TIMELINE_CREATE = true;
        TIMELINE_CLEANUP = true;
      };
    };
  };
}
