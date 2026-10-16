local pack = require('config.pack')

pack.add({ 'https://github.com/neovim/nvim-lspconfig' })
pack.defer({ 'https://github.com/mason-org/mason.nvim' })

-- Servers are found through Mason's bin folder, so Mason itself only loads
-- when something needs installing (or for :Mason)
vim.env.PATH = vim.fs.joinpath(vim.fn.stdpath('data'), 'mason', 'bin') .. ':' .. vim.env.PATH

pack.on_cmds({ 'Mason', 'MasonInstall', 'MasonUpdate', 'MasonUninstall', 'MasonLog' }, function()
  pack.load('mason.nvim')
  require('mason').setup()
end)

if #vim.api.nvim_list_uis() > 0 then
  vim.defer_fn(function()
    require('config.mason').install()
  end, 500)
end

vim.diagnostic.config({
  severity_sort = true,
  virtual_text = { spacing = 2, source = 'if_many' },
  float = { source = true },
})

-- TypeScript: one server per project (see config/typescript.lua) while
-- keeping each server's own root detection from nvim-lspconfig
local ts = require('config.typescript')

local function only_when(name, predicate)
  local base = vim.lsp.config[name]
  local root_dir, root_markers = base.root_dir, base.root_markers
  vim.lsp.config(name, {
    -- lspconfig's tsc shares a binary cache between cmd and root_dir; keep both
    -- from the same load or cmd falls back to a bare `tsc` that isn't on PATH
    cmd = base.cmd,
    root_dir = function(buf, on_dir)
      if not predicate(buf) then
        return
      end
      if type(root_dir) == 'function' then
        return root_dir(buf, on_dir)
      end
      on_dir(vim.fs.root(buf, root_markers or { 'package.json', '.git' }) or vim.fn.getcwd())
    end,
  })
end

only_when('tsc', ts.native)
only_when('vtsls', function(buf)
  return not ts.native(buf)
end)

vim.lsp.config('vtsls', {
  settings = {
    vtsls = { autoUseWorkspaceTsdk = true },
    typescript = { updateImportsOnFileMove = { enabled = 'always' } },
    javascript = { updateImportsOnFileMove = { enabled = 'always' } },
  },
})

vim.lsp.config('lua_ls', {
  settings = {
    Lua = {
      runtime = { version = 'LuaJIT' },
      workspace = { checkThirdParty = false, library = { vim.env.VIMRUNTIME } },
      -- stylua formats Lua (only where a stylua config exists); keep lua_ls from reformatting
      format = { enable = false },
    },
  },
})

vim.lsp.enable({
  'bashls',
  'css_variables',
  'cssls',
  'cssmodules_ls',
  'eslint',
  'html',
  'jsonls',
  'lua_ls',
  'tsc',
  'vtsls',
  'yamlls',
})

-- Neovim's built-ins stay as they are: grn rename, gra code action, grr references,
-- gri implementation, grt type definition, gO symbols, K hover, <C-s> signature
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('user.lsp', { clear = true }),
  callback = function(ev)
    local fzf = require('config.fzf')
    local function map(lhs, rhs, desc, mode)
      vim.keymap.set(mode or 'n', lhs, rhs, { buffer = ev.buf, desc = desc })
    end
    map('gd', vim.lsp.buf.definition, 'Go to definition')
    map('<leader>cd', vim.lsp.buf.definition, 'Definition')
    map('<leader>cv', function()
      vim.cmd.vsplit()
      vim.lsp.buf.definition()
    end, 'Definition in vertical split')
    map('<leader>ch', function()
      vim.cmd.split()
      vim.lsp.buf.definition()
    end, 'Definition in horizontal split')
    map('<leader>ct', vim.lsp.buf.type_definition, 'Type definition')
    map('<leader>cr', fzf.picker('lsp_references'), 'References')
    map('<leader>cs', fzf.picker('lsp_document_symbols'), 'Symbols in file')
    map('<leader>ca', vim.lsp.buf.code_action, 'Code action', { 'n', 'x' })
    map('<leader>ci', function()
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf }), { bufnr = ev.buf })
    end, 'Toggle inlay hints')
  end,
})
