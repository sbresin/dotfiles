return {
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		---@class CatppuccinOptions
		opts = {
			transparent_background = true,
		},
	},
	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = "catppuccin",
		},
	},
}
