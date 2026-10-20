local pack = require('config.pack')

pack.add({
  'https://github.com/folke/which-key.nvim',
  'https://github.com/folke/ts-comments.nvim',
  'https://github.com/folke/flash.nvim',
})
pack.defer({
  'https://github.com/ibhagwan/fzf-lua',
  'https://github.com/nvim-tree/nvim-tree.lua',
  'https://github.com/antosha417/nvim-lsp-file-operations',
  'https://github.com/MagicDuck/grug-far.nvim',
})

-- Cheap to set up, but not needed before the first screen is drawn
pack.later('plugins.editor', function()
  require('ts-comments').setup()
  require('flash').setup()

  local wk = require('which-key')
  wk.setup()
  wk.add({
    { '<leader>a', group = 'AI' },
    { '<leader>b', group = 'buffers' },
    { '<leader>c', group = 'code' },
    { '<leader>d', group = 'debug' },
    { '<leader>e', group = 'diagnostics' },
    { '<leader>f', group = 'find' },
    { '<leader>g', group = 'git' },
    { '<leader>m', group = 'tests' },
    { '<leader>s', group = 'splits/snippets' },
    { '<leader>t', group = 'tree/tabs/terminal' },
  })
end)

vim.keymap.set({ 'n', 'x', 'o' }, 's', function()
  require('flash').jump()
end, { desc = 'Flash: jump' })
vim.keymap.set({ 'n', 'x', 'o' }, 'S', function()
  require('flash').treesitter()
end, { desc = 'Flash: select syntax node' })

-- fzf-lua -------------------------------------------------------------------

local fzf = require('config.fzf')

pack.on_keys({
  { '<leader>ff', fzf.picker('files'), desc = 'Files' },
  { '<leader>fg', fzf.picker('live_grep_glob'), desc = 'Grep (filter files: text -- *.tsx !*.test.*)' },
  { '<leader>fb', fzf.picker('buffers'), desc = 'Buffers' },
  { '<leader>fh', fzf.picker('helptags'), desc = 'Help' },
  { '<leader>fr', fzf.picker('resume'), desc = 'Resume last picker' },
  {
    '<leader>gf',
    function()
      require('config.changed_files').pick()
    end,
    desc = 'Open changed files in a layout',
  },
}, fzf.setup)

-- Route vim.ui.select (code actions, etc.) through fzf-lua once it's loaded
local default_select = vim.ui.select
---@diagnostic disable-next-line: duplicate-set-field
vim.ui.select = function(...)
  vim.ui.select = default_select
  fzf.setup()
  return vim.ui.select(...)
end

-- grug-far: search and replace across files, with a preview of every change -

local setup_grug_far = pack.once(function()
  pack.load('grug-far.nvim')
  require('grug-far').setup()
end)

pack.on_keys({
  {
    '<leader>fs',
    function()
      require('grug-far').open({ prefills = { search = vim.fn.expand('<cword>') } })
    end,
    desc = 'Search and replace in files',
  },
  {
    '<leader>fs',
    function()
      require('grug-far').with_visual_selection()
    end,
    mode = 'x',
    desc = 'Search and replace the selection in files',
  },
}, setup_grug_far)
pack.on_cmds({ 'GrugFar', 'GrugFarWithin' }, setup_grug_far)

-- Built-in undo history browser (Neovim 0.12), loaded on first use
pack.on_cmds({ 'Undotree' }, function()
  vim.cmd.packadd('nvim.undotree')
end)
vim.keymap.set('n', '<leader>u', '<cmd>Undotree<cr>', { desc = 'Undo history' })

-- nvim-tree -----------------------------------------------------------------

local setup_tree = pack.once(function()
  pack.load({ 'nvim-tree.lua', 'nvim-lsp-file-operations' })
  require('nvim-tree').setup({
    sync_root_with_cwd = true,
    view = { adaptive_size = true },
    actions = { open_file = { resize_window = true } },
    renderer = {
      add_trailing = true,
      group_empty = true,
      highlight_git = 'name',
      highlight_opened_files = 'all',
      root_folder_label = ':~',
      indent_markers = { enable = true },
      special_files = { 'README.md', 'Makefile', 'MAKEFILE' },
      icons = {
        glyphs = {
          git = {
            unstaged = '✗',
            staged = '✓',
            unmerged = '',
            renamed = '➜',
            untracked = '★',
            deleted = '',
            ignored = '◌',
          },
        },
      },
    },
  })
  -- Renaming/moving files in the tree asks the language server to update imports
  require('lsp-file-operations').setup()
end)

local function tree(action)
  return function()
    setup_tree()
    action(require('nvim-tree.api'))
  end
end

pack.on_keys({
  {
    '<leader>tt',
    tree(function(api)
      api.tree.toggle()
    end),
    desc = 'File tree',
  },
  {
    '<leader>n',
    tree(function(api)
      api.tree.find_file({ open = true, focus = true })
    end),
    desc = 'Reveal file in tree',
  },
  {
    '<leader>r',
    tree(function(api)
      api.tree.reload()
    end),
    desc = 'Refresh file tree',
  },
}, setup_tree)
pack.on_cmds({ 'NvimTreeToggle', 'NvimTreeOpen', 'NvimTreeFindFile', 'NvimTreeRefresh' }, setup_tree)

-- `nvim some/dir` shows the tree instead of an empty directory buffer
if
  vim.fn.argc() == 1 and vim.fn.isdirectory(vim.fn.argv(0) --[[@as string]]) == 1
then
  setup_tree()
end
