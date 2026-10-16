-- Requires Neovim 0.12+ (vim.pack, nvim-treesitter main)
vim.loader.enable()

vim.g.mapleader = ','
vim.g.maplocalleader = '\\'

require('config.options')
require('config.keymaps')
require('config.autocmds')

require('plugins.ui')
require('plugins.treesitter')
require('plugins.git')
require('plugins.editor')
