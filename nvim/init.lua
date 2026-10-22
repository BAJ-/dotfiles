-- Requires Neovim 0.12+ (vim.pack, nvim-treesitter main)
vim.loader.enable()

vim.g.mapleader = ','
vim.g.maplocalleader = '\\'

require('config.options')
require('config.keymaps')
require('config.autocmds')
require('config.iterm').setup()

-- One module failing (say, its plugin couldn't install offline) must not take
-- the others down; config.pack reports what failed once startup is done
for _, name in ipairs({ 'ui', 'treesitter', 'git', 'editor', 'lsp', 'completion', 'format', 'ai', 'debug', 'test' }) do
  local ok, err = pcall(require, 'plugins.' .. name)
  if not ok then
    require('config.pack').broken('plugins.' .. name, err)
  end
end
