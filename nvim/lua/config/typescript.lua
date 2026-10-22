-- Picks the TypeScript language server per project: TypeScript 7's native
-- server (`tsc --lsp`) when the project's own typescript is 7+, vtsls
-- otherwise. TS 7 has no language-service plugins yet (e.g. Next.js's), so
-- projects stay on vtsls until they upgrade typescript themselves.
local M = {}

local majors = {} ---@type table<string, integer|false>

---Major version of the typescript package a file resolves (nearest node_modules)
---@param path string
---@return integer?
function M.major(path)
  for dir in vim.fs.parents(path) do
    local pkg = dir .. '/node_modules/typescript/package.json'
    if majors[pkg] ~= nil then
      return majors[pkg] or nil
    end
    if vim.uv.fs_stat(pkg) then
      local ok, data = pcall(vim.json.decode, table.concat(vim.fn.readfile(pkg), '\n'))
      local major = ok and tonumber(tostring(data.version or ''):match('^(%d+)')) or nil
      majors[pkg] = major or false
      return major
    end
  end
end

---@param buf integer
---@return boolean
function M.native(buf)
  local major = M.major(vim.api.nvim_buf_get_name(buf))
  return major ~= nil and major >= 7
end

-- Project-wide type check. The language server only reports open files, and
-- none of the servers here support workspace diagnostics, so this runs the
-- project's own tsc (TypeScript 7's native one included) in the background.

local running ---@type vim.SystemObj?

---Nearest tsconfig.json above `path` and the tsc that project resolves
---@param path string
---@return string? root, string? tsc
local function project(path)
  local root = vim.fs.root(path, 'tsconfig.json')
  if not root then
    return nil
  end
  for dir in vim.fs.parents(root .. '/tsconfig.json') do
    local tsc = dir .. '/node_modules/.bin/tsc'
    if vim.fn.executable(tsc) == 1 then
      return root, tsc
    end
  end
  return root, nil
end

---tsc --pretty false: "src/a.ts(3,7): error TS2322: Message", long messages
---continue on indented lines, project-level errors have no location
---@param root string
---@param output string
---@return vim.quickfix.entry[]
local function parse(root, output)
  local items = {}
  for line in output:gmatch('[^\r\n]+') do
    local file, lnum, col, kind, code, text = line:match('^(.-)%((%d+),(%d+)%): (%a+) TS(%d+): (.*)$')
    if file then
      items[#items + 1] = {
        filename = file:sub(1, 1) == '/' and file or vim.fs.joinpath(root, file),
        lnum = tonumber(lnum),
        col = tonumber(col),
        type = kind == 'error' and 'E' or 'W',
        nr = tonumber(code),
        text = text,
      }
    elseif line:match('^%a+ TS%d+: ') then
      items[#items + 1] = { text = line, type = 'E' }
    elseif #items > 0 and line:match('^%s') then
      items[#items].text = items[#items].text .. ' ' .. vim.trim(line)
    end
  end
  return items
end

---Type-check the project the current file belongs to; errors go to the quickfix list
function M.check()
  if running then
    vim.notify('A type check is already running')
    return
  end
  local file = vim.api.nvim_buf_get_name(0)
  local root, tsc = project(file ~= '' and file or (vim.fn.getcwd() .. '/.'))
  if not root then
    vim.notify('No tsconfig.json in this folder or above it', vim.log.levels.WARN)
    return
  end
  if not tsc then
    vim.notify(('TypeScript is not installed for %s (npm install?)'):format(root), vim.log.levels.WARN)
    return
  end

  local name = vim.fn.fnamemodify(root, ':~')
  local progress = { kind = 'progress', title = 'TypeCheck', source = 'typecheck', status = 'running' }
  progress.id = vim.api.nvim_echo({ { name } }, false, progress)
  require('config.iterm').typecheck_started()
  local started = vim.uv.hrtime()
  running = vim.system(
    { tsc, '--noEmit', '--pretty', 'false' },
    { cwd = root, text = true },
    vim.schedule_wrap(function(out)
      running = nil
      local seconds = (vim.uv.hrtime() - started) / 1e9
      local items = parse(root, (out.stdout or '') .. '\n' .. (out.stderr or ''))
      vim.fn.setqflist({}, ' ', { title = 'TypeCheck ' .. name, items = items })
      local problem = out.code ~= 0 and #items == 0
      progress.status = (out.code == 0 or #items > 0) and 'success' or 'failed'
      vim.api.nvim_echo({ { name } }, false, progress)
      require('config.iterm').typecheck_finished(#items, problem)
      if problem then
        local why = vim.trim((out.stderr ~= '' and out.stderr or out.stdout) or ''):match('[^\n]*')
        vim.notify(('Type check failed to run: %s'):format(why), vim.log.levels.ERROR)
      elseif #items == 0 then
        vim.notify(('No type errors in %s (%.1fs)'):format(name, seconds))
      else
        vim.notify(('%d type errors in %s (%.1fs)'):format(#items, name, seconds), vim.log.levels.WARN)
        -- open the list without taking the cursor away from what you're typing
        local win = vim.api.nvim_get_current_win()
        vim.cmd('botright copen')
        vim.api.nvim_set_current_win(win)
      end
    end)
  )
end

return M
