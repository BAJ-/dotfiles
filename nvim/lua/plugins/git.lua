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
