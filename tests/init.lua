-- Add the current working directory (your plugin) to runtimepath
vim.opt.runtimepath:append(vim.fn.getcwd())

-- Ensure Plenary.nvim is available for testing
local plenary_path = vim.fn.stdpath("data") .. "/lazy/plenary.nvim"
if not vim.loop.fs_stat(plenary_path) then
    print("Installing Plenary.nvim...")
    vim.fn.system({
        "git",
        "clone",
        "--depth=1",
        "https://github.com/nvim-lua/plenary.nvim",
        plenary_path,
    })
end
vim.opt.runtimepath:append(plenary_path)

-- Load your plugin after setting up the runtimepath
require("ccsds-hdr").setup({})
