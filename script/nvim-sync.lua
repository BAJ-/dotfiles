-- Run by setup.sh once Neovim has started with this config:
--   nvim --headless "+luafile script/nvim-sync.lua"
-- Startup already installed any missing plugin at its lockfile revision. This
-- moves the other plugins to their lockfile revisions too, deletes plugins the
-- config no longer uses, builds Treesitter parsers, installs Mason packages and
-- fetches blink.cmp's matcher. Exits non-zero when any of it failed or the
-- config itself errors.
local failures = {}

-- Headless messages (ours and the plugins') go to stderr, separated by newlines
local function step(title, fn)
  print('  ' .. title)
  local ok, err = pcall(fn)
  if not ok then
    failures[#failures + 1] = ('%s: %s'):format(title, tostring(err))
  end
end

step('Plugins (lockfile revisions)', function()
  local missing = require('config.pack').failed()
  if #missing > 0 then
    error("couldn't install " .. table.concat(missing, ', '), 0)
  end
  vim.pack.update(nil, { target = 'lockfile', force = true })
  local unused = {}
  for _, plugin in ipairs(vim.pack.get(nil, { info = false })) do
    if not plugin.active then
      unused[#unused + 1] = plugin.spec.name
    end
  end
  if #unused > 0 then
    vim.pack.del(unused)
  end
end)

step('Treesitter parsers', function()
  local ts = require('nvim-treesitter')
  local timeout = 20 * 60 * 1000
  if not ts.install(require('plugins.treesitter').parsers):wait(timeout) or not ts.update():wait(timeout) then
    error('some parsers failed to build (needs tree-sitter-cli and the Xcode command line tools)', 0)
  end
end)

step('Language servers and tools (Mason)', function()
  local failed = require('config.mason').install({ sync = true })
  if #failed > 0 then
    error("couldn't install " .. table.concat(failed, ', '), 0)
  end
end)

step('Completion matcher (blink.cmp)', function()
  -- blink.cmp downloads its prebuilt matcher during setup; wait until it loads
  require('plugins.completion').setup()
  local loaded = vim.wait(5 * 60 * 1000, function()
    return pcall(require, 'blink.cmp.fuzzy.rust')
  end, 500)
  if not loaded then
    error('the prebuilt matcher did not download', 0)
  end
end)

-- Last, so deferred setup has run too: a module error here is a config bug
step('Config loads without errors', function()
  local errors = require('config.pack').errors()
  if #errors > 0 then
    error(table.concat(errors, '; '), 0)
  end
end)

io.stderr:write('\n')
if #failures > 0 then
  io.stderr:write(table.concat(failures, '\n') .. '\n')
  vim.cmd('cquit 1')
end
vim.cmd('qall!')
