local pack = require('config.pack')

pack.defer({ 'https://github.com/stevearc/conform.nvim' })

local prettier = { 'prettierd', 'prettier', stop_after_first = true }

local setup = pack.once(function()
  pack.load('conform.nvim')
  require('conform').setup({
    -- e.g. Lua outside a stylua project: nothing to run, nothing to report
    notify_no_formatters = false,
    formatters_by_ft = {
      css = prettier,
      graphql = prettier,
      html = prettier,
      javascript = prettier,
      javascriptreact = prettier,
      json = prettier,
      jsonc = prettier,
      markdown = prettier,
      scss = prettier,
      typescript = prettier,
      typescriptreact = prettier,
      yaml = prettier,
      lua = { 'stylua', lsp_format = 'never' },
    },
    formatters = {
      -- stylua's defaults (tabs) would reformat this repo, so only run it with a config
      stylua = {
        require_cwd = true,
        cwd = require('conform.util').root_file({ '.stylua.toml', 'stylua.toml' }),
      },
    },
  })
end)

vim.api.nvim_create_user_command('Format', function()
  setup()
  require('conform').format({ lsp_format = 'fallback' })
end, { desc = 'Format buffer' })

-- One hook so the order is fixed: ESLint fixes first, then prettier has the last word
vim.api.nvim_create_autocmd('BufWritePre', {
  group = vim.api.nvim_create_augroup('user.format', { clear = true }),
  callback = function(ev)
    -- Autosave on focus loss can happen mid-typing; don't reformat under the cursor
    if vim.fn.mode():find('^i') then
      return
    end
    -- On autosave, ESLint fix-all could delete an import you haven't used yet
    if not vim.b[ev.buf].autosaving and #vim.lsp.get_clients({ bufnr = ev.buf, name = 'eslint' }) > 0 then
      pcall(vim.cmd, 'LspEslintFixAll')
    end
    setup()
    require('conform').format({ bufnr = ev.buf, timeout_ms = 2000, lsp_format = 'fallback' })
  end,
})
