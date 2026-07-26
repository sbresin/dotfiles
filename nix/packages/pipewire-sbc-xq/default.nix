# PipeWire with configurable SBC-XQ bitpool patch
#
# Adds support for per-channel-mode bitpool settings in WirePlumber's
# monitor.bluez.properties. Values are clamped to each device's max_bitpool,
# so it's safe to set high values globally.
#
# Available settings:
#   bluez5.a2dp.sbc-xq.bitpool.dual-channel  # for Dual Channel mode (default: 43 @ 44.1kHz)
#   bluez5.a2dp.sbc-xq.bitpool.stereo        # for Stereo/Joint Stereo (default: 86 @ 44.1kHz)
#
# Example usage in WirePlumber config:
#   monitor.bluez.properties = {
#     bluez5.a2dp.sbc-xq.bitpool.dual-channel = 52
#   }
#
# NOTE: This package should ONLY be used for services.pipewire.package.
# Using it as a global overlay would cause unnecessary rebuilds of all
# pipewire-dependent packages (like sushi via gstreamer), even though
# this patch only affects runtime Bluetooth codec behavior.
{ pkgs, ... }:
pkgs.pipewire.overrideAttrs (oldAttrs: {
  patches = (oldAttrs.patches or [ ]) ++ [
    ./sbc-xq-configurable-bitpool.patch
  ];
})
