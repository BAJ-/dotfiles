-- nvim-tree replaces netrw; it has to be disabled before plugins load
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- No remote plugins use these providers; skipping their detection speeds up startup
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_node_provider = 0

local o = vim.opt

o.number = true
o.cursorline = true
o.signcolumn = 'yes'
o.wrap = false

o.shiftwidth = 2
o.tabstop = 2
o.expandtab = true

o.ignorecase = true
o.smartcase = true
o.showmatch = true
o.inccommand = 'split'

o.showmode = false
o.splitbelow = true
o.splitright = true
o.confirm = true
o.undofile = true
o.updatetime = 250
o.foldlevel = 99

-- Clipboard provider detection is slow, so attach it after startup
vim.schedule(function()
  vim.o.clipboard = 'unnamedplus'
end)
