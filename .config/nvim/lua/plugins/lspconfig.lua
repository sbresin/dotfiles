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
			},
		},
	},
}
