return {
	{
		"neovim/nvim-lspconfig",
		---@class PluginLspOpts
		opts = {
			---@type lspconfig.options
			servers = {
				-- automatically installed with mason and loaded with lspconfig
				apex_ls = {},
			},
		},
	},
}
