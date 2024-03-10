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
		"rose-pine/neovim",
		name = "rose-pine",
		priority = 1000,
		opts = {
			variant = "auto", -- auto, main, moon, or dawn
			dark_variant = "main", -- main, moon, or dawn

			styles = {
				bold = true,
				italic = true,
				transparency = true,
			},
			-- transparent_background = true,
		},
	},
	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = "rose-pine",
		},
	},
}
