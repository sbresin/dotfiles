-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here
-- restart prettierd after config file save
vim.api.nvim_create_autocmd({'BufWritePost'}, {
    group = vim.api.nvim_create_augroup('RestartPrettierd', {clear = true}),
    pattern = '*prettier*',
    callback = function() vim.fn.system('prettierd restart') end
})
