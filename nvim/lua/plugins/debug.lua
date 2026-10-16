local pack = require('config.pack')

pack.defer({
  'https://github.com/mfussenegger/nvim-dap',
  'https://github.com/igorlfs/nvim-dap-view',
})

local js_filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' }

local setup = pack.once(function()
  pack.load({ 'nvim-dap', 'nvim-dap-view' })
  local dap = require('dap')
  local debug = require('config.debug')

  -- One adapter (vscode-js-debug from Mason) serves every JS debug type
  local js_debug = {
    type = 'server',
    host = 'localhost',
    port = '${port}',
    executable = { command = 'js-debug-adapter', args = { '${port}' } },
  }
  for _, type in ipairs({ 'pwa-node', 'pwa-chrome', 'pwa-msedge', 'node-terminal' }) do
    dap.adapters[type] = js_debug
  end
  -- VS Code's names for the same debuggers, as used in .vscode/launch.json files
  for vscode_type, type in pairs({ node = 'pwa-node', chrome = 'pwa-chrome', msedge = 'pwa-msedge' }) do
    dap.adapters[vscode_type] = function(cb, config)
      config.type = type
      cb(js_debug)
    end
  end

  -- launch.json files are read automatically; list them for JS/TS buffers too
  local vscode = require('dap.ext.vscode')
  for _, type in ipairs({ 'node', 'pwa-node', 'chrome', 'pwa-chrome', 'msedge', 'pwa-msedge', 'node-terminal' }) do
    vscode.type_to_filetypes[type] = js_filetypes
  end
  -- nvim-dap doesn't know VS Code's deprecated ${workspaceRoot} (still in many docs).
  -- on_config listeners, nvim-dap's own variable expansion included, run in no fixed
  -- order: substitute the final value (what ${workspaceFolder} expands to) and copy only
  -- tables that contain the placeholder, so sentinels like dap.ABORT keep their identity
  dap.listeners.on_config['user.workspaceRoot'] = function(config)
    local cwd = vim.fn.getcwd()
    local function has_root(value)
      if type(value) == 'string' then
        return value:find('${workspaceRoot}', 1, true) ~= nil
      elseif type(value) == 'table' then
        for _, v in pairs(value) do
          if has_root(v) then
            return true
          end
        end
      end
      return false
    end
    local function fix(value)
      if type(value) == 'string' then
        return (value:gsub('%${workspaceRoot}', function()
          return cwd
        end))
      elseif type(value) == 'table' and has_root(value) then
        local out = setmetatable({}, getmetatable(value))
        for k, v in pairs(value) do
          out[k] = fix(v)
        end
        return out
      end
      return value
    end
    return fix(config)
  end

  for _, ft in ipairs(js_filetypes) do
    dap.configurations[ft] = debug.configurations()
  end

  -- nvim-dap has no compound launches: attach the renderer once Electron opens its port
  dap.listeners.after.event_initialized['user.electron'] = function(session)
    if session.config.name ~= debug.electron_both then
      return
    end
    debug.wait_for_port(9222, 60000, function(ok)
      if ok then
        dap.run(debug.electron_renderer)
      else
        vim.notify('Electron renderer never opened port 9222', vim.log.levels.WARN)
      end
    end)
  end

  require('dap-view').setup({ auto_toggle = true })
  vim.fn.sign_define('DapBreakpoint', { text = '🦠' })
end)

local function dap(fn, ...)
  local args = { ... }
  return function()
    require('dap')[fn](unpack(args))
  end
end

pack.on_keys({
  { '<leader>ds', dap('continue'), desc = 'Start/continue debugging' },
  { '<leader>dr', dap('run_last'), desc = 'Re-run last debug config' },
  { '<leader>dc', dap('continue'), desc = 'Continue' },
  { '<leader>db', dap('toggle_breakpoint'), desc = 'Toggle breakpoint' },
  {
    '<leader>dB',
    function()
      require('dap').set_breakpoint(vim.fn.input('Condition: '))
    end,
    desc = 'Conditional breakpoint',
  },
  { '<leader>dn', dap('step_over'), desc = 'Step over' },
  { '<leader>di', dap('step_into'), desc = 'Step into' },
  { '<leader>do', dap('step_out'), desc = 'Step out' },
  {
    '<leader>dl',
    function()
      require('dap.ui.widgets').hover()
    end,
    desc = 'Value under cursor',
  },
  {
    '<leader>dv',
    function()
      require('dap-view').toggle()
    end,
    desc = 'Debug view',
  },
  {
    '<leader>dC',
    function()
      require('dap').clear_breakpoints()
      vim.notify('Breakpoints cleared')
    end,
    desc = 'Clear breakpoints',
  },
  {
    '<leader>de',
    function()
      require('dap').clear_breakpoints()
      -- every session: Electron main + renderer, Next.js server + its workers
      require('dap').terminate({ all = true })
      vim.notify('Debugging ended, breakpoints cleared')
    end,
    desc = 'End all debugging, clear breakpoints',
  },
}, setup)
pack.on_cmds({ 'DapContinue', 'DapNew', 'DapToggleBreakpoint', 'DapViewOpen', 'DapViewToggle' }, setup)

return { setup = setup }
