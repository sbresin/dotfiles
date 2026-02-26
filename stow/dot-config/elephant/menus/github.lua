Name = "github"
NamePretty = "GitHub"
Icon = ""
SearchName = true
Cache = false
FixedOrder = true

local bkt = "bkt --ttl=1w --stale=3h -- "

--- Run a command and return its stdout as a string.
local function run(cmd)
	local handle = io.popen(cmd)
	if not handle then
		return ""
	end
	local result = handle:read("*a")
	handle:close()
	return result
end

--- Run a bkt-cached gh command and parse JSON into TSV rows via jq.
--- Each row is split by tab into a list of fields.
local function gh_tsv(gh_args, jq_filter)
	local cmd = bkt .. "gh " .. gh_args .. " | jq -r '" .. jq_filter .. "'"
	local raw = run(cmd)
	local rows = {}
	for line in raw:gmatch("[^\n]+") do
		local fields = {}
		for field in (line .. "\t"):gmatch("(.-)\t") do
			table.insert(fields, field)
		end
		if #fields > 0 then
			table.insert(rows, fields)
		end
	end
	return rows
end

--- Fetch open PRs matching a search flag, returns list of {url, repo, number, title}.
local function fetch_prs(flag)
	return gh_tsv(
		'search prs --state=open ' .. flag .. ' --json number,title,repository,url --limit 50',
		'.[] | [.url, .repository.nameWithOwner, (.number|tostring), .title] | @tsv'
	)
end

function GetEntries()
	local entries = {}

	-- Fetch PRs from all three categories in sequence (bkt makes repeat calls instant)
	local categories = {
		{ flag = "--author=@me",           label = "Created by you" },
		{ flag = "--assignee=@me",         label = "Assigned to you" },
		{ flag = "--review-requested=@me", label = "Review requested" },
	}

	-- Collect PRs and deduplicate by URL, merging category labels
	local pr_map = {}   -- url -> {url, repo, number, title, labels}
	local pr_order = {} -- preserve first-seen order

	for _, cat in ipairs(categories) do
		local rows = fetch_prs(cat.flag)
		for _, row in ipairs(rows) do
			local url = row[1]
			if pr_map[url] then
				pr_map[url].labels = pr_map[url].labels .. " · " .. cat.label
			else
				pr_map[url] = {
					url = url,
					repo = row[2],
					number = row[3],
					title = row[4],
					labels = cat.label,
				}
				table.insert(pr_order, url)
			end
		end
	end

	-- Build PR entries
	for _, url in ipairs(pr_order) do
		local pr = pr_map[url]
		table.insert(entries, {
			Text = "#" .. pr.number .. " " .. pr.title,
			Value = pr.url,
			Icon = "",
			Subtext = pr.repo .. " · " .. pr.labels,
			Actions = {
				open = "xdg-open " .. pr.url,
			},
		})
	end

	-- Discover orgs the user belongs to
	local orgs_raw = run(bkt .. "gh api user/memberships/orgs --jq '.[].organization.login'")
	local owners = { "@me" } -- start with the user's own repos
	for org in orgs_raw:gmatch("[^\n]+") do
		if org ~= "" then
			table.insert(owners, org)
		end
	end

	-- Fetch repos for the user and each org
	for _, owner in ipairs(owners) do
		local owner_flag = ""
		if owner ~= "@me" then
			owner_flag = owner .. " "
		end

		local rows = gh_tsv(
			'repo list ' .. owner_flag .. '--json nameWithOwner,url,description --limit 100',
			'.[] | [.url, .nameWithOwner, (.description // "")] | @tsv'
		)

		for _, row in ipairs(rows) do
			local url = row[1]
			local name = row[2]
			local desc = row[3] or ""

			local subtext = name:match("^(.-)/") or owner
			if desc ~= "" then
				subtext = subtext .. " · " .. desc
			end

			table.insert(entries, {
				Text = name,
				Value = url,
				Icon = "",
				Subtext = subtext,
				Actions = {
					open = "xdg-open " .. url,
				},
			})
		end
	end

	return entries
end
