-- Playwright specs run through Playwright itself (terminal, UI mode, inspector,
-- or the debugger); Vitest and Jest files go through neotest.
local M = {}

local bin = 'node_modules/.bin/playwright'
local imports = { [[from%s*['"]@?playwright]], [[require%(%s*['"]@?playwright]] }

local function imports_playwright(text)
  for _, pattern in ipairs(imports) do
    if text:find(pattern) then
      return true
    end
  end
  return false
end

---@param buf? integer
---@return boolean
function M.is_spec(buf)
  return imports_playwright(table.concat(vim.api.nvim_buf_get_lines(buf or 0, 0, 80, false), '\n'))
end

---Same check for a file on disk; safe in neotest's async discovery
---@param path string
---@return boolean
function M.is_spec_file(path)
  local fd = io.open(path)
  if not fd then
    return false
  end
  local head = fd:read(4096) or ''
  fd:close()
  return imports_playwright(head)
end

---Line of the test or describe block around the cursor. Declarations start with
---a title string, which skips in-body calls such as test.skip(cond) and test.step()
---@return integer?
function M.nearest_line()
  local line =
    vim.fn.search([=[\v^\s*(test|it)(\.(describe|only|skip|fixme|fail|slow|serial|parallel))*\(\s*['"`]]=], 'bcnW')
  return line > 0 and line or nil
end

---Playwright reads file filters as regular expressions, `file:line` picks one test
---@param line? integer
---@return string
function M.file_arg(line)
  local debug = require('config.debug')
  local file = debug.regex_escape(debug.real_file())
  return line and ('%s:%d'):format(file, line) or file
end

local term_buf ---@type integer?
local last_args ---@type string[]?

---Run the Playwright CLI in a terminal split below; the cursor stays put
---@param args string[]
function M.run(args)
  local root = require('config.debug').find_up(bin)
  if not root then
    vim.notify('Playwright not found: no ' .. bin .. ' above this file', vim.log.levels.ERROR)
    return
  end
  last_args = args
  if term_buf and vim.api.nvim_buf_is_valid(term_buf) then
    vim.api.nvim_buf_delete(term_buf, { force = true })
  end
  local win = vim.api.nvim_get_current_win()
  vim.cmd('botright 15new')
  term_buf = vim.api.nvim_get_current_buf()
  vim.fn.jobstart(vim.list_extend({ vim.fs.joinpath(root, bin) }, args), { term = true, cwd = root })
  vim.api.nvim_set_current_win(win)
end

function M.run_nearest()
  M.run({ 'test', M.file_arg(M.nearest_line()) })
end

function M.run_file()
  M.run({ 'test', M.file_arg() })
end

function M.run_last()
  if last_args then
    M.run(last_args)
  end
end

function M.ui()
  M.run({ 'test', '--ui' })
end

---Headed browser plus Playwright Inspector, paused before the first action
function M.inspector()
  M.run({ 'test', M.file_arg(M.nearest_line()), '--debug' })
end

---Nearest test under nvim-dap: breakpoints in the spec and the code it imports
function M.debug_nearest()
  require('plugins.debug').setup()
  for _, config in ipairs(require('config.debug').configurations()) do
    if config.name == 'Playwright: current file' then
      require('dap').run(vim.tbl_extend('force', config, {
        name = 'Playwright: nearest test',
        args = { 'test', M.file_arg(M.nearest_line()), '--workers=1', '--timeout=0' },
      }))
      return
    end
  end
end

return M
