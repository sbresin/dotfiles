local wezterm = require("wezterm")

local config = wezterm.config_builder()

-- helper functions
local is_darwin = function()
	return wezterm.target_triple:find("darwin") ~= nil
end

-- GPU settings
config.front_end = "OpenGL"
config.webgpu_power_preference = "LowPower"
config.enable_wayland = false

-- feature settings
config.term = "wezterm"
config.enable_kitty_keyboard = false

-- window settings
config.window_decorations = "RESIZE"
config.adjust_window_size_when_changing_font_size = false
-- config.window_frame = {
-- 	font_size = 10.0,
-- }

-- appearance settings
config.color_scheme = "Rosé Pine (Gogh)"
config.window_background_opacity = 0.93
-- default font size on darwin is just too small
if is_darwin() then
	config.font_size = 15.0
end

-- tabbar settings
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true

-- additional quickselect patterns
config.quick_select_patterns = {
	-- match email addresses and sfdc usernames
	"(?i)[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z0-9]+",
	-- match sfdc ids
	"(?i)[A-Z0-9]{5}[0-9][A-Z0-9]{9,12}(?=[\\s\\r\\n])",
	-- match flags from commands --help
	"-\\w{1}|--\\w+=?",
}

-- keybindings
local act = wezterm.action

config.keys = {
	{ key = "UpArrow", mods = "SHIFT", action = act.ScrollToPrompt(-1) },
	{ key = "DownArrow", mods = "SHIFT", action = act.ScrollToPrompt(1) },
}

local copy_mode = nil
if wezterm.gui then
	copy_mode = wezterm.gui.default_key_tables().copy_mode
	table.insert(copy_mode, {
		key = "z",
		mods = "NONE",
		action = act.CopyMode("MoveBackwardSemanticZone"),
	})
	table.insert(copy_mode, {
		key = "v",
		mods = "ALT",
		action = act.CopyMode({ SetSelectionMode = "SemanticZone" }),
	})
end

config.key_tables = {
	copy_mode = copy_mode,
}

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
	local left_padding = (window_dims.pixel_width - new_tab_width + minimal_horizontal_padding) / 2

	-- calculate top padding
	local tab_bar_height = cell_height -- 58 -- TODO: upstream ticket, how to get this value?
	local max_rows = math.floor((window_dims.pixel_height - tab_bar_height) / cell_height)
	local new_tab_height = max_rows * cell_height
	local top_padding = (window_dims.pixel_height - tab_bar_height - new_tab_height) / 2 -- left_padding
	-- wezterm.log_info(string.format("row count: %d", tab_dims.rows))
	-- wezterm.log_info(string.format("tab pixel height: %d", tab_dims.pixel_height))
	-- wezterm.log_info(string.format("new tab height px: %d", new_tab_height))
	-- wezterm.log_info(string.format("window height px: %d", window_dims.pixel_height))
	-- wezterm.log_info(string.format("new top padding: %f", top_padding))

	local new_padding = {
		left = left_padding,
		right = 0,
		top = top_padding,
		bottom = 0,
	}
	if
		overrides.window_padding
		and new_padding.top == overrides.window_padding.top
		and new_padding.left == overrides.window_padding.left
	then
		-- padding is same, avoid triggering further changes
		return
	end
	overrides.window_padding = new_padding

	window:set_config_overrides(overrides)
end

wezterm.on("window-resized", function(window) -- , pane )
	recompute_padding(window)
end)

wezterm.on("window-config-reloaded", function(window)
	recompute_padding(window)
end)

return config
