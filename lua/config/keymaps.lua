-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local Util = require("lazyvim.util")
local map = vim.keymap.set

vim.api.nvim_set_keymap("n", "<C-a>", "ggVG", { noremap = true })
vim.api.nvim_set_keymap("n", "vv", "V", { noremap = true })

map({ "n", "v" }, "<leader>cf", function()
	Util.format({ force = true })
end, { desc = "Format" })
