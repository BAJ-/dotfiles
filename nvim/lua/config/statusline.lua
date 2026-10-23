local M = {}

local modes = {
  n = 'NORMAL',
  i = 'INSERT',
  v = 'VISUAL',
  V = 'V-LINE',
  ['\22'] = 'V-BLOCK',
  s = 'SELECT',
  S = 'S-LINE',
  ['\19'] = 'S-BLOCK',
  R = 'REPLACE',
  c = 'COMMAND',
  t = 'TERMINAL',
}

-- Linked to theme groups (no hard-coded colours) and re-applied on :colorscheme
local function highlights()
  vim.api.nvim_set_hl(0, 'StatusLineMode', { link = 'PmenuSel' })
  vim.api.nvim_set_hl(0, 'StatusLineBranch', { link = 'Search' })
  vim.api.nvim_set_hl(0, 'StatusLineText', { link = 'MoreMsg' })
  vim.api.nvim_set_hl(0, 'StatusLineReview', { link = 'DiffText' })
end

-- Running progress messages (tests, :TypeCheck, plugin installs) by name, like
-- "Tests: UserCard.test.tsx": Neovim's own summary only says "0%(1)"
local running = {} ---@type table<integer, string>

---@param data vim.event.progress.data
local function track(data)
  if not data or not data.id then
    return
  end
  if data.status == 'success' or data.status == 'failed' or data.status == 'cancel' or data.percent == 100 then
    running[data.id] = nil
  else
    local text = table.concat(data.text or {})
    running[data.id] = (data.title and data.title ~= '') and (data.title .. ': ' .. text) or text
  end
end

---@return string
function M.progress()
  local items = vim.tbl_values(running)
  table.sort(items)
  return table.concat(items, ' · ')
end

function M.render()
  -- %! expressions run in the focused window's context; this is the window being drawn
  local win = vim.g.statusline_winid
  local buf = vim.api.nvim_win_get_buf(win)
  local active = win == vim.api.nvim_get_current_win()

  -- Set asynchronously by gitsigns, so drawing never waits on git
  local branch = vim.b[buf].gitsigns_head
  local parts = {
    '%#StatusLineBranch# ' .. ((branch and branch ~= '') and branch or '-') .. ' ',
  }
  -- git signs and hunks compare against the review's base while it's open
  if vim.g.review then
    parts[#parts + 1] = '%#StatusLineReview# REVIEW vs ' .. vim.g.review:gsub('%%', '%%%%') .. ' '
  end
  parts[#parts + 1] = '%#StatusLineText# %f%m%r %='

  local diagnostics = vim.diagnostic.status(buf)
  if diagnostics ~= '' then
    parts[#parts + 1] = diagnostics .. '%#StatusLineText# '
  end

  if active then
    -- running things first; the project's kinds of tests (󰙨 Jest · Playwright) stay put next to the mode
    for _, status in ipairs({ vim.lsp.status(), M.progress(), require('config.project_tests').label() }) do
      if status ~= '' then
        parts[#parts + 1] = status:gsub('%%', '%%%%') .. ' '
      end
    end
    local mode = vim.api.nvim_get_mode().mode
    parts[#parts + 1] = '%#StatusLineMode# ' .. (modes[mode] or modes[mode:sub(1, 1)] or mode) .. ' %#StatusLineText#'
  end

  parts[#parts + 1] = ' %y %{&fileencoding!=#""?&fileencoding:&encoding} [%{&fileformat}] %p%% %l:%c '
  return table.concat(parts)
end

function M.setup()
  highlights()
  local group = vim.api.nvim_create_augroup('user.statusline', { clear = true })
  vim.api.nvim_create_autocmd('ColorScheme', { group = group, callback = highlights })
  vim.api.nvim_create_autocmd({ 'DiagnosticChanged', 'LspProgress' }, {
    group = group,
    command = 'redrawstatus',
  })
  vim.api.nvim_create_autocmd('Progress', {
    group = group,
    callback = function(ev)
      track(ev.data)
      vim.cmd.redrawstatus()
    end,
  })
  vim.api.nvim_create_autocmd('User', {
    group = group,
    pattern = 'GitSignsUpdate',
    command = 'redrawstatus',
  })
  vim.o.statusline = "%!v:lua.require'config.statusline'.render()"
end

return M
