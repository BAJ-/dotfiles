-- Debug configurations for JS/TS projects, all through vscode-js-debug.
-- Folders are resolved when a session starts, from the current file upward,
-- so monorepo packages find their own vitest/jest/electron.
local M = {}

---Nearest folder above the current file that contains `rel`
---@param rel string
---@return string?
function M.find_up(rel)
  local file = vim.api.nvim_buf_get_name(0)
  local start = file ~= '' and file or vim.fs.joinpath(vim.fn.getcwd(), '_')
  for dir in vim.fs.parents(start) do
    if vim.uv.fs_stat(vim.fs.joinpath(dir, rel)) then
      return dir
    end
  end
end

---@return string
function M.package_root()
  return vim.fs.root(0, 'package.json') or vim.fn.getcwd()
end

---Current file with symlinks resolved: test runners compare against real paths
---@return string
function M.real_file()
  local file = vim.api.nvim_buf_get_name(0)
  return vim.uv.fs_realpath(file) or file
end

---Playwright reads file arguments as regular expressions
---@param s string
---@return string
function M.regex_escape(s)
  return (s:gsub('[%^%$%(%)%.%[%]%*%+%?%{%}%|\\]', '\\%0'))
end

local locks = {
  { 'pnpm-lock.yaml', 'pnpm' },
  { 'yarn.lock', 'yarn' },
  { 'bun.lock', 'bun' },
  { 'bun.lockb', 'bun' },
  { 'package-lock.json', 'npm' },
}

---The package manager of the package in `dir` (by default the current file's):
---package.json's packageManager, else the nearest lockfile, which in a monorepo
---is at the root, above the package
---@param dir? string
---@return 'npm'|'pnpm'|'yarn'|'bun'
function M.package_manager(dir)
  dir = type(dir) == 'string' and dir or M.package_root()
  local read, lines = pcall(vim.fn.readfile, vim.fs.joinpath(dir, 'package.json'))
  local ok, pkg = pcall(vim.json.decode, read and table.concat(lines, '\n') or '')
  local declared = ok
    and type(pkg) == 'table'
    and type(pkg.packageManager) == 'string'
    and pkg.packageManager:match('^(%a+)@')
  if declared then
    return declared
  end
  for parent in vim.fs.parents(vim.fs.joinpath(dir, '_')) do
    for _, lock in ipairs(locks) do
      if vim.uv.fs_stat(vim.fs.joinpath(parent, lock[1])) then
        return lock[2]
      end
    end
  end
  return 'npm'
end

-- nvim-dap evaluates every function field before it checks for ABORT, so only
-- `cwd` reports a missing tool; the other fields abort quietly
local function cwd_of(rel, what)
  return function()
    local dir = M.find_up(rel)
    if not dir then
      vim.notify(('%s not found: no %s above this file'):format(what, rel), vim.log.levels.ERROR)
      return require('dap').ABORT
    end
    return dir
  end
end

local function bin(rel)
  return function()
    local dir = M.find_up(rel)
    return dir and vim.fs.joinpath(dir, rel) or require('dap').ABORT
  end
end

local skip = { '<node_internals>/**', '**/node_modules/**' }

local forge_script = 'node_modules/@electron-forge/cli/script/vscode.sh'
local electron_bin = 'node_modules/.bin/electron'

---Forge's Vite plugin builds the main process without source maps unless the
---project asks for them, and then breakpoints in src/ never bind
---@param root string
local function check_forge_sourcemaps(root)
  for _, ext in ipairs({ 'mts', 'ts', 'mjs', 'js' }) do
    local name = 'vite.main.config.' .. ext
    local fd = io.open(vim.fs.joinpath(root, name))
    if fd then
      local text = fd:read('*a')
      fd:close()
      if not text:find('sourcemap', 1, true) then
        vim.notify(
          ('Main-process breakpoints need source maps: add `build: { sourcemap: true }` to %s'):format(name),
          vim.log.levels.WARN
        )
      end
      return
    end
  end
end

---How to start Electron for the current file: Forge projects through Forge's
---debug script (builds with its Vite/Webpack plugin first), others directly
---@return { cwd: string, exe: string, args: string[], forge?: boolean }?
local function electron()
  local forge = M.find_up(forge_script)
  if forge then
    -- Forge passes these on to the Electron app
    return {
      cwd = forge,
      exe = vim.fs.joinpath(forge, forge_script),
      args = { '--remote-debugging-port=9222' },
      forge = true,
    }
  end
  local plain = M.find_up(electron_bin)
  if plain then
    return { cwd = plain, exe = vim.fs.joinpath(plain, electron_bin), args = { '.', '--remote-debugging-port=9222' } }
  end
end

M.electron_renderer = {
  name = 'Electron: renderer (attach :9222)',
  type = 'pwa-chrome',
  request = 'attach',
  port = 9222,
  timeout = 60000,
  webRoot = M.package_root,
}

local electron_main = {
  type = 'pwa-node',
  request = 'launch',
  cwd = function()
    local e = electron()
    if not e then
      vim.notify(
        'Electron not found: no Electron Forge or node_modules/.bin/electron above this file',
        vim.log.levels.ERROR
      )
      return require('dap').ABORT
    end
    if e.forge then
      check_forge_sourcemaps(e.cwd)
    end
    return e.cwd
  end,
  runtimeExecutable = function()
    local e = electron()
    return e and e.exe or require('dap').ABORT
  end,
  runtimeArgs = function()
    local e = electron()
    return e and e.args or require('dap').ABORT
  end,
  sourceMaps = true,
  skipFiles = skip,
  console = 'integratedTerminal',
}

M.electron_both = 'Electron: main + renderer'

---@return dap.Configuration[]
function M.configurations()
  return {
    {
      name = 'Node: current file',
      type = 'pwa-node',
      request = 'launch',
      program = '${file}',
      cwd = M.package_root,
      sourceMaps = true,
      skipFiles = skip,
      console = 'integratedTerminal',
    },
    {
      name = 'Node: attach to :9229 (node/next --inspect)',
      type = 'pwa-node',
      request = 'attach',
      port = 9229,
      restart = true,
      cwd = M.package_root,
      sourceMaps = true,
      skipFiles = skip,
    },
    {
      name = 'Node: attach to a process',
      type = 'pwa-node',
      request = 'attach',
      processId = function()
        return require('dap.utils').pick_process({ filter = 'node' })
      end,
      cwd = M.package_root,
      sourceMaps = true,
      skipFiles = skip,
    },
    {
      name = 'Vitest: current file',
      type = 'pwa-node',
      request = 'launch',
      cwd = cwd_of('node_modules/vitest/vitest.mjs', 'Vitest'),
      program = bin('node_modules/vitest/vitest.mjs'),
      args = function()
        return { 'run', '--no-file-parallelism', M.real_file() }
      end,
      autoAttachChildProcesses = true,
      smartStep = true,
      skipFiles = skip,
      console = 'integratedTerminal',
    },
    {
      name = 'Jest: current file',
      type = 'pwa-node',
      request = 'launch',
      cwd = cwd_of('node_modules/jest/bin/jest.js', 'Jest'),
      program = bin('node_modules/jest/bin/jest.js'),
      -- exact path, not a regex: [slug].test.tsx must match itself
      args = function()
        return { '--runInBand', '--watchAll=false', '--runTestsByPath', M.real_file() }
      end,
      sourceMaps = true,
      skipFiles = skip,
      console = 'integratedTerminal',
    },
    {
      name = 'Playwright: current file',
      type = 'pwa-node',
      request = 'launch',
      cwd = cwd_of('node_modules/@playwright/test/cli.js', 'Playwright'),
      program = bin('node_modules/@playwright/test/cli.js'),
      -- no test timeout while paused at a breakpoint
      args = function()
        return { 'test', M.regex_escape(M.real_file()), '--workers=1', '--timeout=0' }
      end,
      skipFiles = skip,
      console = 'integratedTerminal',
    },
    {
      -- VS Code's 'node-terminal' type only exists inside VS Code; standalone js-debug
      -- debugs the same way through a launch: every Node child of the script is attached
      name = 'Next.js: server (dev script)',
      type = 'pwa-node',
      request = 'launch',
      cwd = M.package_root,
      runtimeExecutable = M.package_manager,
      runtimeArgs = { 'run', 'dev' },
      autoAttachChildProcesses = true,
      sourceMaps = true,
      skipFiles = skip,
      console = 'integratedTerminal',
    },
    {
      name = 'Next.js: client in Chrome (:3000)',
      type = 'pwa-chrome',
      request = 'launch',
      url = 'http://localhost:3000',
      webRoot = M.package_root,
    },
    {
      name = 'Vite: client in Chrome (:5173)',
      type = 'pwa-chrome',
      request = 'launch',
      url = 'http://localhost:5173',
      webRoot = M.package_root,
    },
    vim.tbl_extend('force', electron_main, { name = 'Electron: main process' }),
    M.electron_renderer,
    vim.tbl_extend('force', electron_main, { name = M.electron_both }),
  }
end

---Call `cb` once something listens on `port` (or give up after `timeout_ms`).
---Checks both loopbacks: Vite and other dev servers often bind only to ::1.
---@param port integer
---@param timeout_ms integer
---@param cb fun(ok: boolean)
function M.wait_for_port(port, timeout_ms, cb)
  local deadline = vim.uv.now() + timeout_ms
  local function try()
    local hosts = { '127.0.0.1', '::1' }
    local pending, done = #hosts, false
    local function settle(ok)
      pending = pending - 1
      if done then
        return
      elseif ok then
        done = true
        vim.schedule(function()
          cb(true)
        end)
      elseif pending == 0 then
        if vim.uv.now() > deadline then
          vim.schedule(function()
            cb(false)
          end)
        else
          vim.defer_fn(try, 500)
        end
      end
    end
    for _, host in ipairs(hosts) do
      local tcp = assert(vim.uv.new_tcp())
      local started = tcp:connect(host, port, function(err)
        tcp:close()
        settle(not err)
      end)
      if not started then
        tcp:close()
        settle(false)
      end
    end
  end
  try()
end

return M
