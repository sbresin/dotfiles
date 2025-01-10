local wezterm = require("wezterm")

local config = wezterm.config_builder()

-- helper functions
local is_darwin =
    function() return wezterm.target_triple:find("darwin") ~= nil end

-- GPU settings
config.front_end = "OpenGL"
config.webgpu_power_preference = "LowPower"
config.enable_wayland = false

-- feature settings
config.term = "wezterm"
config.enable_kitty_keyboard = false

-- Spawn a xonsh shell in login mode
config.default_prog = {'sh', '-c', 'xonsh -l'}

-- window settings
config.window_decorations = "RESIZE"
config.adjust_window_size_when_changing_font_size = false

-- appearance settings
local theme = require('lua/rose-pine').main
config.colors = theme.colors()
config.window_frame = theme.window_frame();
config.window_background_opacity = 0.95
-- default font size on darwin is just too small
config.font_size = 11.0
if is_darwin() then
	config.font_size = 15.0
end

-- tabbar settings
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true

-- additional quickselect patterns
config.quick_select_patterns = {
    "(?i)[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z0-9]+", -- match email addresses and sfdc usernames
    "(?i)[A-Z0-9]{5}[0-9][A-Z0-9]{9,12}(?=[\\s\\r\\n])", -- match sfdc ids
    -- "force:\\/\\/\\w+::.+@[\\w\\d-_.]+", -- match sf auth urls
    "\\s-\\w{1}|\\s--[\\w-]+=?", -- match flags from commands --help
    '"(.+?)"', -- match quoted strings 
    '`(.+?)`', -- match content in backticks
}

-- keybindings
local act = wezterm.action

config.keys = {
    {key = "UpArrow", mods = "SHIFT", action = act.ScrollToPrompt(-1)},
    {key = "DownArrow", mods = "SHIFT", action = act.ScrollToPrompt(1)}
}

local copy_mode = nil
if wezterm.gui then
    copy_mode = wezterm.gui.default_key_tables().copy_mode
    table.insert(copy_mode, {
        key = "z",
        mods = "NONE",
        action = act.CopyMode("MoveBackwardSemanticZone")
    })
    table.insert(copy_mode, {
        key = "v",
        mods = "ALT",
        action = act.CopyMode({SetSelectionMode = "SemanticZone"})
    })
end

config.key_tables = {copy_mode = copy_mode}

-- compute padding -> center horizontally and bottom align vertically
local function recompute_padding(window)
    local window_dims = window:get_dimensions()
    local overrides = window:get_config_overrides() or {}

    -- calculate cell dimensions
    local active_tab = window:active_tab()
    local tab_dims = active_tab:get_size()
    local cell_width = tab_dims.pixel_width / tab_dims.cols
    local cell_height = tab_dims.pixel_height / tab_dims.rows

    -- calculate left padding
    local max_cols = math.floor(window_dims.pixel_width / cell_width)
    local new_tab_width = max_cols * cell_width
    local minimal_horizontal_padding = cell_width
    local left_padding = (window_dims.pixel_width - new_tab_width +
                             minimal_horizontal_padding) / 2

    -- calculate top padding
    local tab_bar_height = cell_height -- 58 -- TODO: upstream ticket, how to get this value?
    local max_rows = math.floor((window_dims.pixel_height - tab_bar_height) /
                                    cell_height)
    local new_tab_height = max_rows * cell_height
    local top_padding = (window_dims.pixel_height - tab_bar_height -
                            new_tab_height) / 2 -- left_padding
    -- wezterm.log_info(string.format("row count: %d", tab_dims.rows))
    -- wezterm.log_info(string.format("tab pixel height: %d", tab_dims.pixel_height))
    -- wezterm.log_info(string.format("new tab height px: %d", new_tab_height))
    -- wezterm.log_info(string.format("window height px: %d", window_dims.pixel_height))
    -- wezterm.log_info(string.format("new top padding: %f", top_padding))

    local new_padding = {
        left = left_padding,
        right = 0,
        top = top_padding,
        bottom = 0
    }
    if overrides.window_padding and new_padding.top ==
        overrides.window_padding.top and new_padding.left ==
        overrides.window_padding.left then
        -- padding is same, avoid triggering further changes
        return
    end
    overrides.window_padding = new_padding

    window:set_config_overrides(overrides)
end

wezterm.on("window-resized", function(window) -- , pane )
    recompute_padding(window)
end)

wezterm.on("window-config-reloaded",
           function(window) recompute_padding(window) end)

local function log_proc(proc, indent)
    indent = indent or ''
    -- wezterm.log_info(indent .. 'pid=' .. proc.pid .. ', name=' .. proc.name ..
    --                      ', status=' .. proc.status)
    -- wezterm.log_info(indent .. 'argv=' .. table.concat(proc.argv, ' '))
    -- wezterm.log_info(indent .. 'executable=' .. proc.executable .. ', cwd=' ..
    --                      proc.cwd)
    for pid, child in pairs(proc.children) do log_proc(child, indent .. '  ') end

    -- 	10:42:34.942  INFO   logging > lua: pid=8805, name=xonsh, status=Sleep
    -- 10:42:34.942  INFO   logging > lua: argv=/nix/store/nmqxyr00in2arwrq5qd1qipsanz1yrn5-python3-3.11.10/bin/python3.11 /nix/store/dvc7wnipn59p1dzarfsdpamljgm9s30i-python3.11-xonsh-0.18.4/bin/xonsh -l
    -- 10:42:34.942  INFO   logging > lua: executable=/nix/store/nmqxyr00in2arwrq5qd1qipsanz1yrn5-python3-3.11.10/bin/python3.11, cwd=/home/sebe
end

wezterm.on('mux-is-process-stateful', function(proc)
    -- log_proc(proc)
    -- wezterm.log_info(proc.children)
    -- config.skip_close_confirmation_for_processes_named does somehow not work
    if proc.name == 'xonsh' and
        (proc.children == nil or not next(proc.children)) then return false end

    -- Just use the default behavior
    return nil
end)

return config
