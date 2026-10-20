-- Helpers for the snippets in nvim/snippets/, and a picker that browses the
-- snippets available in the current buffer (including the filetypes it
-- extends) and inserts one
local M = {}

-- File name without extensions; index files take their folder's name
local function base_name()
  local path = vim.api.nvim_buf_get_name(0)
  if path == '' then
    return ''
  end
  local base = vim.fs.basename(path):match('^[^.]*')
  if base == 'index' then
    base = vim.fs.basename(vim.fs.dirname(path)):match('^[^.]*')
  end
  return base
end

local function upper_first(word)
  return (word:gsub('^%l', string.upper))
end

local function pascal(name)
  local words = {}
  for word in name:gmatch('%w+') do
    words[#words + 1] = upper_first(word)
  end
  local result = table.concat(words)
  return result:match('^%u') and result or ''
end

M.upper_first = upper_first

-- user-card.tsx -> UserCard
function M.component_name()
  local name = pascal(base_name())
  return name ~= '' and name or 'Component'
end

-- ThemeContext.tsx and theme-provider.tsx -> Theme
function M.context_name()
  local name = pascal(base_name()):gsub('Context$', ''):gsub('Provider$', '')
  return name ~= '' and name or 'Name'
end

-- use-window-size.ts and useWindowSize.ts -> useWindowSize
function M.hook_name()
  local base = base_name()
  if not base:match('^use[%u%-_]') then
    return 'useName'
  end
  return 'use' .. pascal(base:sub(4))
end

local function read_json(path)
  if not vim.uv.fs_stat(path) then
    return nil
  end
  local ok, data = pcall(vim.json.decode, table.concat(vim.fn.readfile(path), '\n'))
  return ok and type(data) == 'table' and data or nil
end

-- Major version of React for the current file: the installed one, else the
-- range in the nearest package.json that lists it. nil when there's neither.
function M.react_major()
  local file = vim.api.nvim_buf_get_name(0)
  local dir = file ~= '' and vim.fs.dirname(file) or vim.fn.getcwd()
  local up = { path = dir, upward = true, limit = math.huge }
  for _, modules in ipairs(vim.fs.find('node_modules', vim.tbl_extend('force', up, { type = 'directory' }))) do
    local react = read_json(modules .. '/react/package.json')
    if react and type(react.version) == 'string' then
      return tonumber(react.version:match('^%d+'))
    end
  end
  for _, path in ipairs(vim.fs.find('package.json', vim.tbl_extend('force', up, { type = 'file' }))) do
    local pkg = read_json(path) or {}
    for _, field in ipairs({ 'dependencies', 'devDependencies', 'peerDependencies' }) do
      local range = type(pkg[field]) == 'table' and pkg[field].react
      local major = type(range) == 'string' and range:match('%d+')
      if major then
        return tonumber(major)
      end
    end
  end
end

local imports_react = {}

-- React hook snippets show in .tsx files, and in .ts files that import React
-- or are named use*. Called for every hook snippet on every completion
-- request, so the import scan is cached until the buffer changes.
function M.is_react_file()
  local buf = vim.api.nvim_get_current_buf()
  if vim.bo[buf].filetype == 'typescriptreact' or base_name():match('^use[%u%-_]') then
    return true
  end
  local tick = vim.api.nvim_buf_get_changedtick(buf)
  local cached = imports_react[buf]
  if not cached or cached.tick ~= tick then
    local found = false
    for _, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, 200, false)) do
      if line:find([=[from%s*['"]react['"]]=]) or line:find([=[require%(%s*['"]react['"]%s*%)]=]) then
        found = true
        break
      end
    end
    cached = { tick = tick, value = found }
    imports_react[buf] = cached
  end
  return cached.value
end

local not_code = { comment = true, string_fragment = true, regex_pattern = true, jsx_text = true }

-- Postfix snippets (.log, .if...) only show right after `expression.` in code.
-- Reads the cursor itself: blink passes the line minus its last character.
-- Parses first, as the tree may not have caught up with the last few keys.
function M.after_expression()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local last = vim.api.nvim_get_current_line():sub(1, col):find('[%w_$%)%]\'"`!]%.%a*$')
  if not last then
    return false
  end
  local ok, node = pcall(function()
    vim.treesitter.get_parser(0):parse()
    return vim.treesitter.get_node({ pos = { row - 1, last - 1 } })
  end)
  return not (ok and node and not_code[node:type()])
end

function M.pick()
  local ls = require('luasnip')
  local labels, by_label = {}, {}
  for _, ft in ipairs(ls.get_snippet_filetypes()) do
    for _, snip in ipairs(ls.get_snippets(ft) or {}) do
      local label = ('%-6s %s  [%s]'):format(snip.trigger, snip.name or snip.trigger, ft)
      if not by_label[label] then
        by_label[label] = snip
        labels[#labels + 1] = label
      end
    end
  end
  if #labels == 0 then
    vim.notify('No snippets for ' .. vim.bo.filetype)
    return
  end

  require('config.fzf').setup()
  require('fzf-lua').fzf_exec(labels, {
    prompt = 'Snippets> ',
    actions = {
      ['enter'] = function(selected)
        local snip = by_label[selected[1]]
        if not snip then
          return
        end
        vim.cmd.startinsert()
        vim.schedule(function()
          ls.snip_expand(snip)
        end)
      end,
    },
  })
end

return M
