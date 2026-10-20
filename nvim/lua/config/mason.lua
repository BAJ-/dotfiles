-- Language servers and tools installed through Mason. Interactive sessions
-- install anything missing in the background; setup.sh calls
-- install({ sync = true }).
local M = {}

M.packages = {
  'bash-language-server',
  'copilot-language-server',
  'css-lsp',
  'css-variables-language-server',
  'cssmodules-language-server',
  'eslint-lsp',
  'gh-actions-language-server',
  'html-lsp',
  'js-debug-adapter',
  'json-lsp',
  'lua-language-server',
  'prettierd',
  'stylua',
  'vtsls',
  'yaml-language-server',
}

---Cheap check (no Mason load): package folders that don't exist yet
---@return string[]
function M.missing()
  local root = vim.fs.joinpath(vim.fn.stdpath('data'), 'mason', 'packages')
  return vim.tbl_filter(function(name)
    return vim.uv.fs_stat(vim.fs.joinpath(root, name)) == nil
  end, M.packages)
end

---@param opts? { sync?: boolean }
---@return string[] failed package names (sync only)
function M.install(opts)
  opts = opts or {}
  local missing = M.missing()
  if #missing == 0 then
    return {}
  end

  require('config.pack').load('mason.nvim')
  require('mason').setup()
  local registry = require('mason-registry')

  local pending, failed, started = 0, {}, false
  local function report()
    if #failed > 0 then
      vim.notify('Mason could not install: ' .. table.concat(failed, ', '), vim.log.levels.ERROR)
    elseif not opts.sync then
      vim.notify('Mason installed: ' .. table.concat(missing, ', '))
    end
  end

  if not opts.sync then
    vim.notify('Mason is installing: ' .. table.concat(missing, ', '))
  end
  registry.refresh(function()
    for _, name in ipairs(missing) do
      local ok, pkg = pcall(registry.get_package, name)
      if not ok then
        failed[#failed + 1] = name
      elseif not pkg:is_installing() then
        pending = pending + 1
        pkg:install({}, function(success)
          pending = pending - 1
          if not success then
            failed[#failed + 1] = name
          end
          if pending == 0 then
            vim.schedule(report)
          end
        end)
      end
    end
    started = true
    if pending == 0 then
      vim.schedule(report)
    end
  end)

  if opts.sync then
    vim.wait(15 * 60 * 1000, function()
      return started and pending == 0
    end, 200)
  end
  return failed
end

return M
