local M = {}

---Delete the current buffer but keep its windows open. Asks before
---discarding unsaved changes (the old mapping used :bd! and lost them).
function M.delete()
  local buf = vim.api.nvim_get_current_buf()

  if vim.bo[buf].modified then
    local name = vim.fn.bufname(buf) ~= '' and vim.fn.bufname(buf) or '[No Name]'
    local choice = vim.fn.confirm(('Save changes to "%s"?'):format(name), '&Yes\n&No\n&Cancel', 3)
    if choice == 1 then
      vim.cmd.write()
    elseif choice ~= 2 then
      return
    end
  end

  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    vim.api.nvim_win_call(win, function()
      local alt = vim.fn.bufnr('#')
      if alt > 0 and alt ~= buf and vim.bo[alt].buflisted then
        vim.cmd.buffer(alt)
      else
        pcall(vim.cmd.bprevious)
      end
      if vim.api.nvim_win_get_buf(win) == buf then
        vim.cmd.enew()
      end
    end)
  end

  if vim.api.nvim_buf_is_valid(buf) then
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
  end
end

return M
