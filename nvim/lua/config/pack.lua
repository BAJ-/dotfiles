-- Thin layer over vim.pack: `add` loads plugins during startup, `defer` only
-- installs them and they are :packadd-ed on first use (keys, commands, events).
local M = {}

local function pack_opts(extra)
  -- Headless runs (setup.sh, CI) have nobody to answer the install prompt
  return vim.tbl_extend('force', { confirm = #vim.api.nvim_list_uis() > 0 }, extra or {})
end

---@param specs (string|vim.pack.Spec)[]
function M.add(specs)
  vim.pack.add(specs, pack_opts())
end

---@param specs (string|vim.pack.Spec)[]
function M.defer(specs)
  vim.pack.add(specs, pack_opts({ load = function() end }))
end

local loaded = {}

---@param names string|string[] plugin directory names
function M.load(names)
  for _, name in ipairs(type(names) == 'table' and names or { names }) do
    if not loaded[name] then
      loaded[name] = true
      vim.cmd.packadd(name)
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
