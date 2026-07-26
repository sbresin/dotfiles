-- ============================================================================
-- HYPRLAND LUA CONFIG
-- Migrated from hyprlang (hyprland.conf) on 2026-06-17
-- ============================================================================
--
-- EMERGENCY INFO:
-- If this config fails to load, Hyprland provides fallback keybinds:
--   SUPER+Q = terminal, SUPER+R = run, SUPER+M = exit
--
-- Your custom emergency keybinds (if config loads partially):
--   SUPER+SHIFT+D = force internal display on + DPMS on
--   SUPER+SHIFT+M = rebind UCSI driver + reprobe DRM connectors
--
-- To reload config: hyprctl reload
-- To switch back to old config: hyprctl reload full-reset (after renaming files)
-- ============================================================================
-- ====================
-- ====  MONITORS  ====
-- ====================
-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- ASUS ProArt PA279CRV - 4K with 10-bit, wide color gamut, VRR
hl.monitor({
    output = "desc:ASUSTek COMPUTER INC PA279CRV T9LMSB015299",
    mode = "3840x2160@60",
    position = "0x0",
    scale = "auto",
    bitdepth = 10,
    cm = "wide",
    vrr = 1
})

-- Fallback for other monitors
hl.monitor({output = "", mode = "preferred", position = "auto", scale = "auto"})

-- ====================
-- ====  XWAYLAND  ====
-- ====================

hl.config({xwayland = {force_zero_scaling = true}})

hl.env("GDK_SCALE", "2")
hl.env("QT_SCALE_FACTOR", "2")

-- ===============================
-- ====  ENVIRONMENT VARIABLES ===
-- ===============================

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/
-- Note: Most env vars are set in ~/.config/uwsm/env when using UWSM

hl.env("XCURSOR_SIZE", "32")
hl.env("HYPRCURSOR_SIZE", "32")

-- ======================
-- ====  MY PROGRAMS ====
-- ======================

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

local terminal = "app2unit -s a -- foot"
local fileManager = "app2unit -s a -- nautilus -w"
local menu = "socat /dev/null UNIX-CONNECT:$XDG_RUNTIME_DIR/walker/walker.sock"
local notificationToggle = "swaync-client -t"
local lock = "pkill -x hyprlock; sleep 0.3; hyprlock"
local emojiPicker =
    "simplemoji --no-close --close-on-copy --copy-command wl-copy --font 'Apple Color Emoji' --show-preview --fuzzing-search --show-search --recent-type mixed --background-color '#26233a' --primary-color '#e0def4' --corner-radius 5"

-- ====================
-- ====  AUTOSTART ====
-- ====================

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/
-- Services (hypridle, hyprpaper, hyprsunset, hyprpolkitagent) managed by home-manager

hl.on("hyprland.start", function()
    -- Random wallpaper
    hl.exec_cmd("~/.config/hypr/scripts/hyprpaper_random.sh")
    -- Monitor hotplug listener
    hl.exec_cmd("~/.config/hypr/scripts/monitor_listener.sh")
    -- DDC/CI brightness cache for external monitors
    hl.exec_cmd("~/.config/hypr/scripts/ddci-listener.sh")
    -- Notification daemon
    hl.exec_cmd("app2unit -s b -- swaync")
    -- Walker is managed by a systemd user service (see nix/modules/nixos/desktop)
end)

-- =========================
-- ====  LOOK AND FEEL  ====
-- =========================

-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/

hl.config({
    general = {
        gaps_in = 5,
        gaps_out = 10,
        gaps_workspaces = 30,

        border_size = 2,

        -- Rose Pine theme colors
        col = {
            active_border = {
                colors = {"rgb(ebbcba)", "rgb(9ccfd8)"},
                angle = 45
            },
            inactive_border = "rgba(6e6a86aa)"
        },

        -- Enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = true,
        extend_border_grab_area = 2,

        -- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/
        allow_tearing = false,

        layout = "dwindle"
    },

    decoration = {
        rounding = 5,
        rounding_power = 2,

        -- Transparency of focused and unfocused windows
        active_opacity = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled = true,
            range = 4,
            render_power = 3,
            color = 0xee1a1a1a
        },

        blur = {enabled = true, size = 5, passes = 2, vibrancy = 0.1696}
    },

    animations = {enabled = true}
})

-- ======================
-- ====  ANIMATIONS  ====
-- ======================

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/

hl.curve("easeOutQuint", {type = "bezier", points = {{0.23, 1}, {0.32, 1}}})
hl.curve("easeInOutCubic", {type = "bezier", points = {{0.65, 0.05}, {0.36, 1}}})
hl.curve("linear", {type = "bezier", points = {{0, 0}, {1, 1}}})
hl.curve("almostLinear", {type = "bezier", points = {{0.5, 0.5}, {0.75, 1}}})
hl.curve("quick", {type = "bezier", points = {{0.15, 0}, {0.1, 1}}})

hl.animation({leaf = "global", enabled = true, speed = 10, bezier = "default"})
hl.animation({
    leaf = "border",
    enabled = true,
    speed = 5.39,
    bezier = "easeOutQuint"
})
hl.animation({
    leaf = "windows",
    enabled = true,
    speed = 4.79,
    bezier = "easeOutQuint"
})
hl.animation({
    leaf = "windowsIn",
    enabled = true,
    speed = 4.1,
    bezier = "easeOutQuint",
    style = "popin 87%"
})
hl.animation({
    leaf = "windowsOut",
    enabled = true,
    speed = 1.49,
    bezier = "linear",
    style = "popin 87%"
})
hl.animation({
    leaf = "fadeIn",
    enabled = true,
    speed = 1.73,
    bezier = "almostLinear"
})
hl.animation({
    leaf = "fadeOut",
    enabled = true,
    speed = 1.46,
    bezier = "almostLinear"
})
hl.animation({leaf = "fade", enabled = true, speed = 3.03, bezier = "quick"})
hl.animation({
    leaf = "layers",
    enabled = true,
    speed = 3.81,
    bezier = "easeOutQuint"
})
hl.animation({
    leaf = "layersIn",
    enabled = true,
    speed = 4,
    bezier = "easeOutQuint",
    style = "fade"
})
hl.animation({
    leaf = "layersOut",
    enabled = true,
    speed = 1.5,
    bezier = "linear",
    style = "fade"
})
hl.animation({
    leaf = "fadeLayersIn",
    enabled = true,
    speed = 1.79,
    bezier = "almostLinear"
})
hl.animation({
    leaf = "fadeLayersOut",
    enabled = true,
    speed = 1.39,
    bezier = "almostLinear"
})
hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 1.94,
    bezier = "almostLinear",
    style = "fade"
})
hl.animation({
    leaf = "workspacesIn",
    enabled = true,
    speed = 1.21,
    bezier = "almostLinear",
    style = "fade"
})
hl.animation({
    leaf = "workspacesOut",
    enabled = true,
    speed = 1.94,
    bezier = "almostLinear",
    style = "fade"
})

-- ==========================
-- ====  WORKSPACE RULES ====
-- ==========================

-- Ref https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
-- "Smart gaps" / "No gaps when only"

hl.workspace_rule({workspace = "w[tv1]s[false]", gaps_out = 0, gaps_in = 0})
hl.workspace_rule({workspace = "f[1]s[false]", gaps_out = 0, gaps_in = 0})

hl.window_rule({
    name = "smart-gaps-tiled-tv1",
    match = {float = false, workspace = "w[tv1]s[false]"},
    border_size = 0,
    rounding = 8
})

hl.window_rule({
    name = "smart-gaps-tiled-f1",
    match = {float = false, workspace = "f[1]s[false]"},
    border_size = 0,
    rounding = 0
})

-- ===================
-- ====  LAYOUTS  ====
-- ===================

-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/
hl.config({dwindle = {preserve_split = true}})

-- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/
hl.config({master = {new_status = "master"}})

-- ================
-- ====  MISC  ====
-- ================

hl.config({
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        key_press_enables_dpms = true,
        focus_on_activate = true,
        initial_workspace_tracking = 2
    }
})

-- ======================
-- ====  BINDS CONFIG ===
-- ======================

hl.config({binds = {workspace_back_and_forth = true}})

-- =================
-- ====  INPUT  ====
-- =================

-- See https://wiki.hypr.land/Configuring/Basics/Variables/#input

hl.config({
    input = {
        kb_layout = "us",
        kb_variant = "altgr-weur",
        kb_options = "eurosign:e,caps:escape_shifted_capslock,numpad:mac",
        kb_model = "",
        kb_rules = "",

        follow_mouse = 1,

        sensitivity = 0, -- -1.0 to 1.0, 0 means no modification

        touchpad = {natural_scroll = true}
    }
})

-- Gestures
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Gestures/
hl.gesture({fingers = 3, direction = "horizontal", action = "workspace"})

-- ======================
-- ====  KEYBINDINGS ====
-- ======================

-- See https://wiki.hypr.land/Configuring/Basics/Binds/

local mainMod = "SUPER"

-- ---- Window Management ----

-- Switch between windows in a floating workspace
hl.bind(mainMod .. " + Tab", function()
    hl.dispatch(hl.dsp.window.cycle_next())
    hl.dispatch(hl.dsp.window.bring_to_top())
end)

hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + W",
        hl.dsp.exec_cmd("~/.config/hypr/scripts/hyprpaper_random.sh"))
hl.bind(mainMod .. " + SHIFT + W",
        hl.dsp.exec_cmd("~/.config/hypr/scripts/workspace_setup.sh"))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("uwsm stop"))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd(notificationToggle))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.exec_cmd(lock))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({action = "toggle"}))
hl.bind(mainMod .. " + SHIFT + V",
        hl.dsp.exec_cmd("~/.config/hypr/scripts/toggle_pip.sh"))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + CTRL + Space", hl.dsp.exec_cmd(emojiPicker))

-- ---- Focus Movement ----

hl.bind(mainMod .. " + left", hl.dsp.focus({direction = "left"}))
hl.bind(mainMod .. " + right", hl.dsp.focus({direction = "right"}))
hl.bind(mainMod .. " + up", hl.dsp.focus({direction = "up"}))
hl.bind(mainMod .. " + down", hl.dsp.focus({direction = "down"}))
hl.bind(mainMod .. " + H", hl.dsp.focus({direction = "left"}))
hl.bind(mainMod .. " + L", hl.dsp.focus({direction = "right"}))
hl.bind(mainMod .. " + K", hl.dsp.focus({direction = "up"}))
hl.bind(mainMod .. " + J", hl.dsp.focus({direction = "down"}))

-- ---- Workspaces ----

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({workspace = i}))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({workspace = i}))
end

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S",
        hl.dsp.window.move({workspace = "special:magic"}))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({workspace = "e+1"}))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({workspace = "e-1"}))

-- ---- Mouse Binds ----

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), {mouse = true})
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), {mouse = true})

-- ---- Lid Switch ----

hl.bind("switch:on:Lid Switch",
        hl.dsp.exec_cmd("~/.config/hypr/scripts/monitor_toggle.sh"),
        {locked = true})
hl.bind("switch:off:Lid Switch",
        hl.dsp.exec_cmd("~/.config/hypr/scripts/monitor_toggle.sh"),
        {locked = true})

-- Toggle internal display (only enable if lid is open)
hl.bind(mainMod .. " + D", function()
    local handle = io.popen("hyprctl monitors all -j")
    local result = handle:read("*a")
    handle:close()

    -- Check if eDP-1 is currently disabled
    local disabled = result:match('"name":%s*"eDP%-1".-"disabled":%s*true')

    if disabled then
        -- Only enable if lid is open
        local lid = io.open("/proc/acpi/button/lid/LID0/state", "r")
        local state = lid:read("*a")
        lid:close()

        if state:match("open") then
            hl.monitor({
                output = "eDP-1",
                mode = "preferred",
                position = "auto",
                scale = "auto",
                disabled = false
            })
            hl.dispatch(hl.dsp.dpms("on"))
            hl.exec_cmd("notify-send -t 2000 'Display' 'Internal screen enabled'")
        else
            hl.exec_cmd("notify-send -t 2000 'Display' 'Cannot enable: lid is closed'")
        end
    else
        hl.monitor({ output = "eDP-1", disabled = true })
        hl.exec_cmd("notify-send -t 2000 'Display' 'Internal screen disabled'")
    end
end, {locked = true})

-- ---- Emergency Display Binds ----

-- Emergency: force internal display on + DPMS on (for when screen doesn't wake after suspend)
hl.bind(mainMod .. " + SHIFT + D", function()
    -- Log a diagnostic snapshot first, so we have something to work with if
    -- this doesn't fully recover (see freeze_analyze.sh).
    hl.exec_cmd("~/.config/hypr/scripts/freeze_debug.sh D-emergency")
    hl.monitor({
        output = "eDP-1",
        mode = "preferred",
        position = "auto",
        scale = "auto",
        disabled = false
    })
    hl.dispatch(hl.dsp.dpms("on"))
    hl.exec_cmd("~/.config/hypr/scripts/monitor_toggle.sh")
end, {locked = true})

-- Emergency: rebind UCSI driver + reprobe DRM connectors (for stuck USB-C DP Alt Mode after suspend)
hl.bind(mainMod .. " + SHIFT + M", function()
    -- Log a diagnostic snapshot before attempting the fix (see freeze_analyze.sh).
    hl.exec_cmd("~/.config/hypr/scripts/freeze_debug.sh M-emergency")
    hl.exec_cmd("systemctl start drm-reprobe-rescue.service")
end, {locked = true})



-- ---- Media Keys ----

-- Volume
hl.bind("XF86AudioRaiseVolume",
        hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
        {locked = true, repeating = true})
hl.bind("XF86AudioLowerVolume",
        hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
        {locked = true, repeating = true})
hl.bind("XF86AudioMute",
        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
        {locked = true, repeating = true})
hl.bind("XF86AudioMicMute",
        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
        {locked = true, repeating = true})

-- Brightness (acts on the screen where the focused window is)
hl.bind("XF86MonBrightnessUp",
        hl.dsp.exec_cmd("~/.config/hypr/scripts/brightness.sh brightness up"),
        {locked = true, repeating = true})
hl.bind("XF86MonBrightnessDown", hl.dsp
            .exec_cmd("~/.config/hypr/scripts/brightness.sh brightness down"),
        {locked = true, repeating = true})

-- Contrast: external monitors only (DDC/CI), no-op on internal
hl.bind("SHIFT + XF86MonBrightnessUp",
        hl.dsp.exec_cmd("~/.config/hypr/scripts/brightness.sh contrast up"),
        {locked = true, repeating = true})
hl.bind("SHIFT + XF86MonBrightnessDown",
        hl.dsp.exec_cmd("~/.config/hypr/scripts/brightness.sh contrast down"),
        {locked = true, repeating = true})

-- Player control (requires playerctl)
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), {locked = true})
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"),
        {locked = true})
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"),
        {locked = true})
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), {locked = true})

-- Evdev keycode fallbacks (for devices where XKB keysym mapping doesn't work, e.g. kanata virtual device)
hl.bind("code:163", hl.dsp.exec_cmd("playerctl next"), {locked = true})
hl.bind("code:164", hl.dsp.exec_cmd("playerctl play-pause"), {locked = true})
hl.bind("code:165", hl.dsp.exec_cmd("playerctl previous"), {locked = true})

-- ---- Screenshots ----

hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("hyprcap shot window -c -n -z"))
hl.bind("Print", hl.dsp.exec_cmd("hyprcap shot monitor:active -c -n -z"))
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("hyprcap shot region -c -n -z"))

-- ---- Debug ----

-- Log timestamp when display freeze is observed
hl.bind(mainMod .. " + SHIFT + F",
        hl.dsp.exec_cmd("~/.config/hypr/scripts/freeze_debug.sh"))

-- =======================
-- ====  WINDOW RULES ====
-- =======================

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/

-- ---- Transparency Toggle ----
-- Performance toggle: force terminal windows opaque and disable blur
-- Toggled with SUPER+T

local transparencyRule = hl.window_rule({
    name = "no-transparency",
    match = {
        class = "^(com\\.mitchellh\\.ghostty|foot|org\\.wezfurlong\\.wezterm)$"
    },
    force_rgbx = true
})
transparencyRule:set_enabled(false) -- starts disabled

local transparencyDisabled = false

hl.bind(mainMod .. " + T", function()
    transparencyDisabled = not transparencyDisabled
    transparencyRule:set_enabled(transparencyDisabled)
    -- hl.config({decoration = {blur = {enabled = not transparencyDisabled}}})
end)

-- ---- Suppress Maximize ----
-- Ignore maximize requests from apps

hl.window_rule({
    name = "suppress-maximize",
    match = {class = ".*"},
    suppress_event = "maximize"
})

-- ---- XWayland Drag Fix ----
-- Fix some dragging issues with XWayland

hl.window_rule({
    name = "xwayland-drag-fix",
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false
    },
    no_focus = true
})

-- ---- Peek-a-meet Floating ----
-- Allow peek-a-meet to float as picture-in-picture

hl.window_rule({
    name = "peek-a-meet-float",
    match = {title = "peek-a-meet \\(floating\\)"},
    float = true,
    pin = true,
    no_blur = true,
    border_size = 0,
    no_shadow = true,
    no_dim = true,
    persistent_size = true,
    move = "(monitor_w-window_w-20) (monitor_h-window_h-20)"
})
