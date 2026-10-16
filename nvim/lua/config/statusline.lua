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
    '%#StatusLineText# %f%m%r %=',
  }

  local diagnostics = vim.diagnostic.status(buf)
  if diagnostics ~= '' then
    parts[#parts + 1] = diagnostics .. '%#StatusLineText# '
  end

  if active then
    for _, status in ipairs({ vim.lsp.status(), vim.ui.progress_status() }) do
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
  vim.api.nvim_create_autocmd({ 'DiagnosticChanged', 'LspProgress', 'Progress' }, {
    group = group,
    command = 'redrawstatus',
  })
  vim.api.nvim_create_autocmd('User', {
    group = group,
    pattern = 'GitSignsUpdate',
    command = 'redrawstatus',
  })
  vim.o.statusline = "%!v:lua.require'config.statusline'.render()"
end

return M
