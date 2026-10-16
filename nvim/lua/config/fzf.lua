-- Shared fzf-lua loader so pickers in any module set it up exactly once
local M = {}

M.setup = require('config.pack').once(function()
  require('config.pack').load('fzf-lua')
  require('fzf-lua').setup()
  require('fzf-lua').register_ui_select()
end)

---@param picker string fzf-lua picker name
---@param opts? table
---@return fun()
function M.picker(picker, opts)
  return function()
    M.setup()
    require('fzf-lua')[picker](opts)
  end
end

return M
