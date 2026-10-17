-- Thin layer over vim.pack: `add` loads plugins during startup, `defer` only
-- installs them and they are :packadd-ed on first use (keys, commands, events).
local M = {}

local function pack_opts(extra)
  -- Headless runs (setup.sh, CI) have nobody to answer the install prompt
  return vim.tbl_extend('force', { confirm = #vim.api.nvim_list_uis() > 0 }, extra or {})
end

local failed = {} ---@type string[] plugins that couldn't install
local broken = {} ---@type { name: string, err: string }[] config modules that errored
local reported = false

local function report()
  reported = true
  if #failed > 0 then
    local names = vim.tbl_map(function(b)
      return b.name
    end, broken)
    local off = #names > 0 and (' Not loaded: %s.'):format(table.concat(names, ', ')) or ''
    vim.notify(
      ("Couldn't install %s (offline?).%s Restart Neovim to retry."):format(table.concat(failed, ', '), off),
      vim.log.levels.WARN
    )
  elseif #broken > 0 then
    local lines = vim.tbl_map(function(b)
      return ('%s: %s'):format(b.name, b.err)
    end, broken)
    vim.notify('Parts of the config failed to load:\n' .. table.concat(lines, '\n'), vim.log.levels.ERROR)
  end
end

-- One message after startup: a failed install explains everything that broke
-- because of it; without one, a module error is a bug and is shown in full
vim.api.nvim_create_autocmd('VimEnter', {
  once = true,
  callback = function()
    vim.schedule(report)
  end,
})

---Record a config module that errored (reported with the rest after startup)
---@param name string
---@param err any
function M.broken(name, err)
  broken[#broken + 1] = { name = name, err = tostring(err):match('[^\n]*') }
  if reported and #failed == 0 then
    vim.notify(('%s failed: %s'):format(name, broken[#broken].err), vim.log.levels.ERROR)
  end
end

---vim.pack.add loads what is installed, then raises for plugins it couldn't
---install (offline, no GitHub access); note those and carry on
local function add(specs, opts)
  local ok, err = pcall(vim.pack.add, specs, opts)
  if ok then
    return
  end
  local names = 0
  for name in tostring(err):gmatch('`([^`\n]+)`:') do
    failed[#failed + 1] = name
    names = names + 1
  end
  if names == 0 then
    failed[#failed + 1] = tostring(err):match('[^\n]*')
  end
end

---Plugins that couldn't install this session (setup.sh fails on these)
---@return string[]
function M.failed()
  return vim.deepcopy(failed)
end

---Run setup that isn't needed before the first screen is drawn
---@param name string reported if it errors
---@param fn fun()
function M.later(name, fn)
  vim.schedule(function()
    local ok, err = pcall(fn)
    if not ok then
      M.broken(name, err)
    end
  end)
end

---@param specs (string|vim.pack.Spec)[]
function M.add(specs)
  add(specs, pack_opts())
end

---@param specs (string|vim.pack.Spec)[]
function M.defer(specs)
  add(specs, pack_opts({ load = function() end }))
end

local loaded = {}

---@param names string|string[] plugin directory names
function M.load(names)
  for _, name in ipairs(type(names) == 'table' and names or { names }) do
    if not loaded[name] then
      -- :packadd of a missing plugin is silent; say why the plugin isn't there
      if not vim.uv.fs_stat(vim.fs.joinpath(vim.fn.stdpath('data'), 'site', 'pack', 'core', 'opt', name)) then
        error(('%s is not installed; restart Neovim to install it'):format(name), 0)
      end
      vim.cmd.packadd(name)
      loaded[name] = true
    end
  end
end

---Returns a function that runs `setup` exactly once
---@param setup fun()
function M.once(setup)
  local done = false
  return function()
    if not done then
      done = true
      setup()
    end
  end
end

---Keymaps that run `setup` (once) before their action
---@param keys {[1]: string, [2]: fun(), mode?: string|string[], desc?: string}[]
---@param setup fun()
function M.on_keys(keys, setup)
  local ensure = M.once(setup)
  for _, key in ipairs(keys) do
    vim.keymap.set(key.mode or 'n', key[1], function()
      ensure()
      key[2]()
    end, { desc = key.desc })
  end
end

---User commands that run `setup` (once), then re-run themselves with the real definition
---@param cmds string[]
---@param setup fun()
function M.on_cmds(cmds, setup)
  local ensure = M.once(setup)
  for _, name in ipairs(cmds) do
    vim.api.nvim_create_user_command(name, function(args)
      pcall(vim.api.nvim_del_user_command, name)
      ensure()
      vim.cmd({
        cmd = name,
        args = args.fargs,
        bang = args.bang,
        range = args.range > 0 and { args.line1, args.line2 } or nil,
      })
    end, { nargs = '*', bang = true, range = true })
  end
end

return M
