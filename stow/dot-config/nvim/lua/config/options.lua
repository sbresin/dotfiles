-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
-- Apex file types
vim.filetype.add({
    extension = {
        cls = "apexcode",
        apex = "apexcode",
        trigger = "apexcode",
        soql = "soql",
        sosl = "sosl"
    }
})

vim.treesitter.language.register("apex", {"apexcode"})

-- anything less would be insane
vim.opt.tabstop = 4;
