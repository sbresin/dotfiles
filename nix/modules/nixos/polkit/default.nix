{...}: {
  security.polkit = {
    enable = true;
    debug = true;
    extraConfig = ''
      /* Log authorization checks. */
      polkit.addRule(function(action, subject) {
        // Make sure to set { security.polkit.debug = true; } in configuration.nix
        polkit.log("user " +  subject.user + " is attempting action " + action.id + " from PID " + subject.pid);
      });

      // users in wheel group can manage networks
      polkit.addRule(function(action, subject) {
        if (/^org\.freedesktop\.NetworkManager\./.test(action.id) && subject.local && subject.active && subject.isInGroup("wheel")) {
          return polkit.Result.YES;
        }
      });

      // users in storage group can do udisk internal mounts
      polkit.addRule(function(action, subject) {
        if (("org.freedesktop.udisks2.filesystem-mount-system" === action.id || "org.freedesktop.udisks.filesystem-mount-system-internal" === action.id) &&
          subject.local && subject.active && subject.isInGroup("storage")) {
          return polkit.Result.YES;
        }
      });
    '';
  };
}
