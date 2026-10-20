local pack = require('config.pack')

pack.add({ 'https://github.com/lewis6991/gitsigns.nvim' })

require('gitsigns').setup({
  on_attach = function(buf)
    local gs = require('gitsigns')
    local function map(lhs, rhs, desc)
      vim.keymap.set('n', lhs, rhs, { buffer = buf, desc = desc })
    end
    map(']h', function()
      gs.nav_hunk('next')
    end, 'Next git hunk')
    map('[h', function()
      gs.nav_hunk('prev')
    end, 'Previous git hunk')
    map('<leader>gs', gs.stage_hunk, 'Stage hunk')
    map('<leader>gr', gs.reset_hunk, 'Reset hunk')
    map('<leader>gp', gs.preview_hunk, 'Preview hunk')
    map('<leader>gb', function()
      gs.blame_line({ full = true })
    end, 'Blame line')
    map('<leader>gd', gs.diffthis, 'Diff against index')
  end,
})

-- Built-in directory/file diff (Neovim 0.12); an opt-in plugin loaded on first use
pack.on_cmds({ 'DiffTool' }, function()
  vim.cmd.packadd('nvim.difftool')
end)

-- Review the branch against its base, file by file (config/review.lua)
vim.api.nvim_create_user_command('Review', function(args)
  require('config.review').start(args.args)
end, {
  nargs = '?',
  complete = function(lead)
    return require('config.review').complete(lead)
  end,
  desc = 'Review changes against a branch (default: the remote default branch)',
})
vim.api.nvim_create_user_command('ReviewEnd', function()
  require('config.review').stop()
end, { desc = 'End the review' })
vim.keymap.set('n', '<leader>gv', function()
  require('config.review').toggle()
end, { desc = 'Review the branch on/off' })

-- GitHub links to the line or selection (config/github.lua)
vim.keymap.set({ 'n', 'x' }, '<leader>go', function()
  require('config.github').link(false)
end, { desc = 'Open on GitHub' })
vim.keymap.set({ 'n', 'x' }, '<leader>gy', function()
  require('config.github').link(true)
end, { desc = 'Copy GitHub link' })
