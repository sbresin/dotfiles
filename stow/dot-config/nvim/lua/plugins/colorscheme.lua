return {
    {
        "rose-pine/neovim",
        name = "rose-pine",
        priority = 1000,
        opts = {
            variant = "auto", -- auto, main, moon, or dawn
            dark_variant = "main", -- main, moon, or dawn

            styles = {bold = true, italic = false, transparency = true},
            -- transparent_background = true,
            highlight_groups = {Comment = {italic = true}}
        }
    }, {"LazyVim/LazyVim", opts = {colorscheme = "rose-pine"}}
}
