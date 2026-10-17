-- Debounced autosave so dev servers (HMR) see changes without :w.
-- Saves never happen while typing: only after leaving insert mode, after
-- normal-mode edits, or when Neovim loses focus. During an autosave
-- `vim.b.autosaving` is true so format-on-save can skip ESLint fix-all,
-- which could otherwise delete an import you haven't used yet.
local M = {}

M.delay_ms = 1000

local timers = {} ---@type table<integer, uv.uv_timer_t>

local function savable(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return false
  end
  local bo = vim.bo[buf]
  return bo.buftype == '' and bo.modified and bo.modifiable and not bo.readonly and vim.api.nvim_buf_get_name(buf) ~= ''
end

---@param buf integer
function M.save(buf)
  if not savable(buf) then
    return
  end
  vim.api.nvim_buf_call(buf, function()
    vim.b.autosaving = true
    vim.cmd('silent! lockmarks update')
    vim.b.autosaving = false
  end)
end

local function stop(buf)
  local timer = timers[buf]
  if timer then
    timer:stop()
    timer:close()
    timers[buf] = nil
  end
end

---@param buf integer
function M.schedule(buf)
  stop(buf)
  local timer = assert(vim.uv.new_timer())
  timers[buf] = timer
  timer:start(
    M.delay_ms,
    0,
    vim.schedule_wrap(function()
      stop(buf)
      -- Typing resumed in this buffer; InsertLeave will reschedule
      if vim.api.nvim_get_current_buf() == buf and vim.fn.mode():find('^i') then
        return
      end
      M.save(buf)
    end)
  )
end

function M.setup()
  local group = vim.api.nvim_create_augroup('user.autosave', { clear = true })
  vim.api.nvim_create_autocmd({ 'InsertLeave', 'TextChanged' }, {
    group = group,
    callback = function(ev)
      M.schedule(ev.buf)
    end,
  })
  vim.api.nvim_create_autocmd('FocusLost', {
    group = group,
    callback = function()
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        stop(buf)
        M.save(buf)
      end
    end,
  })
  vim.api.nvim_create_autocmd('BufDelete', {
    group = group,
    callback = function(ev)
      stop(ev.buf)
    end,
  })
end

return M
