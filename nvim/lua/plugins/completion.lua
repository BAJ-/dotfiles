local pack = require('config.pack')

-- blink's plugin/ file runs at startup to register LSP completion capabilities;
-- LuaSnip and the completion setup wait until they're first needed
pack.add({ { src = 'https://github.com/saghen/blink.cmp', version = vim.version.range('1.*') } })
pack.defer({ { src = 'https://github.com/L3MON4D3/LuaSnip', version = vim.version.range('2.*') } })

local setup = pack.once(function()
  pack.load('LuaSnip')
  local ls = require('luasnip')
  require('luasnip.loaders.from_lua').lazy_load({ paths = { vim.fn.stdpath('config') .. '/snippets' } })
  -- filetype_extend isn't recursive, so every filetype lists all of its parents
  ls.filetype_extend('typescript', { 'javascript' })
  ls.filetype_extend('typescriptreact', { 'typescript', 'javascript' })
  ls.filetype_extend('javascriptreact', { 'javascript' })

  require('blink.cmp').setup({
    keymap = {
      -- <CR> only accepts an item you've selected, like the old nvim-cmp setup
      preset = 'enter',
      -- menu open: next item; otherwise accept ghost text, then snippet jump
      ['<Tab>'] = {
        'select_next',
        function()
          return vim.lsp.inline_completion.get()
        end,
        'snippet_forward',
        'fallback',
      },
      ['<S-Tab>'] = { 'select_prev', 'snippet_backward', 'fallback' },
    },
    completion = {
      list = { selection = { preselect = false, auto_insert = true } },
      documentation = { auto_show = true, auto_show_delay_ms = 300 },
    },
    signature = { enabled = true },
    snippets = { preset = 'luasnip' },
    sources = { default = { 'lsp', 'path', 'snippets', 'buffer' } },
    fuzzy = { implementation = 'prefer_rust_with_warning' },
  })
end)

vim.api.nvim_create_autocmd({ 'InsertEnter', 'CmdlineEnter' }, {
  group = vim.api.nvim_create_augroup('user.completion', { clear = true }),
  once = true,
  callback = setup,
})

vim.keymap.set('n', '<leader>ss', function()
  setup()
  require('config.snippets').pick()
end, { desc = 'Browse snippets' })

return { setup = setup }
