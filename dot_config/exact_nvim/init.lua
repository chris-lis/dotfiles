-- Configure leader and local leader keys
-- NOTE: Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
vim.g.mapleader = " "
vim.g.maplocalleader = " " -- TODO: decide on local leader

-- Set NeoVim options
require('config.settings')
-- Install and load lazy.nvim package manager
require('config.lazy')
-- Setup keymaps ???
require('config.keymaps')
-- Setup autocommands ???
require('config.autocmds')

