{
  inputs,
  pkgs,
  system,
  ...
}:
inputs.razer-laptop-control.packages.${system}.default.overrideAttrs (oldAttrs: {
  buildInputs = with pkgs; [
    udev
    dbus-glib
    gdk-pixbuf
    atk
    cairo
    pango
    gtk3
  ];
})
