-- Which kinds of tests the project in the current folder has (Vitest, Jest,
-- Playwright) and where its Playwright folders are, for the status line and the
-- test list (,mt). Read in the background from git's list of files, once per
-- folder, so it finds them in monorepos and in subfolders like tests/e2e
local M = {}

---@class ProjectTests
---@field vitest boolean
---@field jest boolean
---@field playwright string[] folders with a Playwright config

---@type table<string, ProjectTests|false> false while it's being read
local found = {}
---@type table<string, fun(tests: ProjectTests)[]>
local waiting = {}
-- bumped when a config file is saved, so a read that started before is ignored
local generation = 0

local configs = { 'vitest.config.*', 'vitest.workspace.*', 'jest.config.*', 'playwright.config.*' }

---@param path string
---@return table?
local function read_json(path)
  local fd = io.open(path)
  if not fd then
    return
  end
  local ok, data = pcall(vim.json.decode, fd:read('*a'))
  fd:close()
  return ok and type(data) == 'table' and data or nil
end

---@param dir string
---@param files string[] relative to dir
---@return ProjectTests
local function classify(dir, files)
  local tests = { vitest = false, jest = false, playwright = {} }
  -- without a config anywhere, Playwright runs from the package that depends on it
  local depends = {}
  for _, rel in ipairs(files) do
    local name = vim.fs.basename(rel)
    local folder = vim.fs.normalize(vim.fs.joinpath(dir, vim.fs.dirname(rel)))
    if name == 'package.json' then
      local pkg = read_json(vim.fs.joinpath(dir, rel)) or {}
      local deps = {}
      for _, field in ipairs({ 'dependencies', 'devDependencies' }) do
        if type(pkg[field]) == 'table' then
          deps = vim.tbl_extend('force', deps, pkg[field])
        end
      end
      tests.vitest = tests.vitest or deps.vitest ~= nil
      tests.jest = tests.jest or deps.jest ~= nil or pkg.jest ~= nil
      if deps['@playwright/test'] then
        depends[#depends + 1] = folder
      end
    elseif name:match('^vitest%.') then
      tests.vitest = true
    elseif name:match('^jest%.') then
      tests.jest = true
    elseif name:match('^playwright%.') then
      tests.playwright[#tests.playwright + 1] = folder
    end
  end
  if #tests.playwright == 0 then
    tests.playwright = depends
  end
  table.sort(tests.playwright)
  return tests
end

---@param name string
---@return boolean
local function is_config(name)
  return name:match('^vitest%.config%.')
    or name:match('^vitest%.workspace%.')
    or name:match('^jest%.config%.')
    or name:match('^playwright%.config%.')
end

---Outside a git repository, only the folder itself is looked at
---@param dir string
---@return string[]
local function own_files(dir)
  local files = {}
  for name, type in vim.fs.dir(dir) do
    if type == 'file' and (name == 'package.json' or is_config(name)) then
      files[#files + 1] = name
    end
  end
  return files
end

---@param dir string
---@param done fun(tests: ProjectTests)
local function read(dir, done)
  local cmd = { 'git', 'ls-files', '-z', '--cached', '--others', '--exclude-standard', '--' }
  for _, glob in ipairs(vim.list_extend({ 'package.json' }, configs)) do
    cmd[#cmd + 1] = ':(glob)**/' .. glob
  end
  cmd[#cmd + 1] = ':(exclude,glob)**/node_modules/**'
  local ok = pcall(vim.system, cmd, { cwd = dir, text = true }, function(result)
    vim.schedule(function()
      local files = result.code == 0 and vim.split(result.stdout, '\0', { plain = true, trimempty = true })
        or own_files(dir)
      done(classify(dir, files))
    end)
  end)
  if not ok then
    done(classify(dir, own_files(dir)))
  end
end

---The tests of the project in `dir`, or nil while they're still being looked for
---@param dir? string defaults to the current folder
---@return ProjectTests?
function M.get(dir)
  dir = dir or vim.fn.getcwd()
  if found[dir] == nil then
    found[dir] = false
    local started = generation
    -- not straight away: the status line asks while it's being drawn
    vim.schedule(function()
      read(dir, function(tests)
        if started ~= generation then
          return
        end
        found[dir] = tests
        for _, fn in ipairs(waiting[dir] or {}) do
          fn(tests)
        end
        waiting[dir] = nil
        vim.cmd.redrawstatus()
      end)
    end)
  end
  return found[dir] or nil
end

---Calls `fn` with the project's tests, as soon as they're known
---@param dir string
---@param fn fun(tests: ProjectTests)
function M.when_ready(dir, fn)
  local tests = M.get(dir)
  if tests then
    fn(tests)
  else
    waiting[dir] = waiting[dir] or {}
    table.insert(waiting[dir], fn)
  end
end

---"Vitest / Jest", "Vitest" or "Jest": the test list's name for that area
---@param tests ProjectTests
---@return string?
function M.unit_name(tests)
  local names = {}
  if tests.vitest then
    names[#names + 1] = 'Vitest'
  end
  if tests.jest then
    names[#names + 1] = 'Jest'
  end
  return #names > 0 and table.concat(names, ' / ') or nil
end

---For the status line: "󰙨 Jest · Playwright", or '' when the project has no tests
---@return string
function M.label()
  local tests = M.get()
  if not tests then
    return ''
  end
  local names = {}
  if tests.vitest then
    names[#names + 1] = 'Vitest'
  end
  if tests.jest then
    names[#names + 1] = 'Jest'
  end
  if #tests.playwright > 0 then
    names[#names + 1] = 'Playwright'
  end
  return #names > 0 and ('󰙨 ' .. table.concat(names, ' · ')) or ''
end

vim.api.nvim_create_autocmd('BufWritePost', {
  group = vim.api.nvim_create_augroup('user.project_tests', { clear = true }),
  pattern = vim.list_extend({ 'package.json' }, configs),
  callback = function()
    found = {}
    generation = generation + 1
    vim.cmd.redrawstatus()
  end,
})

return M
