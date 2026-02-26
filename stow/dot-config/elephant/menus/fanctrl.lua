Name = "fanctrl"
NamePretty = "Fan Control"
Icon = "weather-windy-symbolic"
SearchName = true
Cache = true
FixedOrder = true

local strategy_order = {
	"laziest",
	"lazy",
	"medium",
	"agile",
	"very-agile",
	"deaf",
	"aeolus",
}

local strategy_icons = {
	laziest = "power-profile-power-saver-symbolic",
	lazy = "power-profile-power-saver-symbolic",
	medium = "power-profile-balanced-symbolic",
	agile = "power-profile-balanced-symbolic",
	["very-agile"] = "power-profile-performance-symbolic",
	deaf = "power-profile-performance-symbolic",
	aeolus = "power-profile-performance-symbolic",
}

local strategy_descriptions = {
	laziest = "Silent until 45°C, gentle ramp",
	lazy = "15% baseline, slow response",
	medium = "Moderate cooling, steady response",
	agile = "Moderate cooling, fast response",
	["very-agile"] = "Moderate cooling, very fast response",
	deaf = "Aggressive cooling, 100% at 60°C",
	aeolus = "Max cooling, 100% at 65°C",
}

function GetEntries()
	local entries = {}

	-- Get current strategy
	local current_handle = io.popen("fw-fanctrl --output-format JSON print current")
	local current_json = current_handle:read("*a")
	current_handle:close()
	local current = current_json:match('"strategy":%s*"([^"]+)"')

	-- Get available strategies to validate against
	local list_handle = io.popen("fw-fanctrl --output-format JSON print list")
	local list_json = list_handle:read("*a")
	list_handle:close()
	local strategies_array = list_json:match("%[(.-)%]")

	local available = {}
	if strategies_array then
		for strategy in strategies_array:gmatch('"([^"]+)"') do
			available[strategy] = true
		end
	end

	for _, strategy in ipairs(strategy_order) do
		if available[strategy] then
			local desc = strategy_descriptions[strategy] or ""
			local entry = {
				Text = strategy,
				Value = strategy,
				Icon = strategy_icons[strategy] or "weather-windy-symbolic",
				Subtext = desc,
				Actions = {
					use = "fw-fanctrl use " .. strategy,
				},
			}
			if strategy == current then
				entry.State = { "current" }
				entry.Subtext = desc .. " · active"
			end
			table.insert(entries, entry)
		end
	end

	return entries
end
