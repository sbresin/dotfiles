local prettier = {
	formatCommand = '~/.local/share/nvim/mason/bin/prettierd "${INPUT}"',
	formatStdin = true,
	-- env = {
	--   string.format('PRETTIERD_DEFAULT_CONFIG=%s', vim.fn.expand('~/.config/nvim/utils/linter-config/.prettierrc.json')),
	-- },
}

return {
	{
		"neovim/nvim-lspconfig",
		---@class PluginLspOpts
		opts = {
			servers = {
				-- automatically installed with mason and loaded with lspconfig
				apex_ls = {
					apex_enable_semantic_errors = true, -- Whether to allow Apex Language Server to surface semantic errors
					apex_enable_completion_statistics = false, -- Disable telemetry
				},
				efm = {
					init_options = { documentFormatting = true, documentRangeFormatting = true },
					filetypes = { "lua", "apexcode" },
					settings = {
						rootMarkers = { ".git/" },
						languages = {
							lua = {
								{
									formatCommand = "lua-format -i",
									formatStdin = true,
								},
							},
							apexcode = {
								prettier,
								-- {
								-- 	--  ${--tab-width=tabWidth} ${--use-tabs=!insertSpaces}
								-- 	-- ~/.local/share/nvim/mason/bin/prettier
								-- 	formatCommand = "node_modules/.bin/prettier --stdin --stdin-filepath '${INPUT}' ${--range-start=charStart} ${--range-end=charEnd}",
								-- 	formatStdin = true,
								-- 	-- formatCanRange = true,
								-- 	rootMarkers = {
								-- 		"sfdx-project.json",
								-- 	},
								-- },
							},
						},
					},
				},
			},
		},
	},
}
