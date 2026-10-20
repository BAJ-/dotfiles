local pack = require('config.pack')

-- blink's plugin/ file runs at startup to register LSP completion capabilities;
-- LuaSnip and the completion setup wait until they're first needed
pack.add({ { src = 'https://github.com/saghen/blink.cmp', version = vim.version.range('1.*') } })
pack.defer({ { src = 'https://github.com/L3MON4D3/LuaSnip', version = vim.version.range('2.*') } })

-- Emmet's server offers abbreviations anywhere in a JSX file, so `user.n`
-- would turn into <user className="n">. Its items only stay where markup goes:
-- between JSX tags. An abbreviation like `div.card>h2+p` doesn't parse as JSX,
-- so the check parses the file with a plain word in its place.
local function in_jsx_markup(buf, range)
  local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local row = range.start.line
  local line = lines[row + 1]
  if not lang or not line then
    return false
  end
  local from = vim.str_byteindex(line, 'utf-16', range.start.character, false)
  local to = vim.str_byteindex(line, 'utf-16', range['end'].character, false)
  lines[row + 1] = line:sub(1, from) .. 'x' .. line:sub(to + 1)
  local ok, parser = pcall(vim.treesitter.get_string_parser, table.concat(lines, '\n'), lang)
  if not ok then
    return false
  end
  local node = parser:parse()[1]:root():named_descendant_for_range(row, from, row, from)
  while node do
    local type = node:type()
    if type == 'jsx_element' then
      return true
    elseif type == 'jsx_expression' or type == 'jsx_opening_element' or type == 'jsx_self_closing_element' then
      return false
    end
    node = node:parent()
  end
  return false
end

local function without_emmet_in_code(ctx, items)
  -- the response can arrive after its buffer is gone
  if not vim.api.nvim_buf_is_valid(ctx.bufnr) then
    return items
  end
  local ft = vim.bo[ctx.bufnr].filetype
  if ft ~= 'javascriptreact' and ft ~= 'typescriptreact' then
    return items
  end
  -- every Emmet item in a response covers the same abbreviation
  local allowed
  return vim.tbl_filter(function(item)
    if item.client_name ~= 'emmet_language_server' then
      return true
    end
    if allowed == nil then
      local range = item.textEdit and (item.textEdit.range or item.textEdit.insert)
      allowed = range ~= nil and in_jsx_markup(ctx.bufnr, range)
    end
    return allowed
  end, items)
end

local setup = pack.once(function()
  pack.load('LuaSnip')
  local ls = require('luasnip')
  ls.setup({
    -- moving out of an unfinished snippet ends it, so Tab can't jump back into it
    region_check_events = 'CursorMoved,CursorMovedI,InsertEnter',
    delete_check_events = 'TextChanged,InsertLeave',
    -- mirrored names (setCount from count) follow as you type
    update_events = 'TextChanged,TextChangedI',
  })
  -- filetype_extend isn't recursive, so every filetype lists all of its parents.
  -- It goes before lazy_load, which loads the current buffer's snippets right away.
  -- react-hooks is a snippet file, not a real filetype; its snippets decide
  -- for themselves whether a .ts file is a React one.
  ls.filetype_extend('typescript', { 'javascript', 'react-hooks' })
  ls.filetype_extend('typescriptreact', { 'typescript', 'javascript', 'react-hooks' })
  ls.filetype_extend('javascriptreact', { 'javascript' })
  require('luasnip.loaders.from_lua').lazy_load({ paths = { vim.fn.stdpath('config') .. '/snippets' } })

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
    sources = {
      default = { 'lsp', 'path', 'snippets', 'buffer' },
      providers = { lsp = { transform_items = without_emmet_in_code } },
    },
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
