local group = vim.api.nvim_create_augroup('user.core', { clear = true })

-- Reload buffers changed outside Neovim (git, formatters, AI agents)
vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter' }, {
  group = group,
  callback = function()
    if vim.fn.getcmdwintype() == '' then
      vim.cmd.checktime()
    end
  end,
})

require('config.autosave').setup()
