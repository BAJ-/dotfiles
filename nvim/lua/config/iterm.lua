-- iTerm2 integration:
-- - the tab's status dot and a macOS notification when tests or a type check
--   finish, so you can work elsewhere and still see how it went
-- - opening the files that bin/nvim-open sends here (Cmd-click in iTerm2)
-- Other terminals get none of the escape codes.
local M = {}

local colors = { busy = '#d29922', ok = '#3fb950', bad = '#f85149' }
-- A good result only needs a glance; a stale one would hide the dev server's
-- status, as a tab shows its focused pane's status
local ok_for_ms = 10000
local focused = true
local generation = 0

local function in_iterm()
  return (vim.env.TERM_PROGRAM == 'iTerm.app' or vim.env.LC_TERMINAL == 'iTerm2') and not vim.env.TMUX
end

local function send(sequence)
  local function now()
    if in_iterm() and #vim.api.nvim_list_uis() > 0 then
      pcall(vim.api.nvim_ui_send, sequence)
    end
  end
  -- right away, so clearing the status on exit happens before Neovim is gone
  if vim.in_fast_event() then
    vim.schedule(now)
  else
    now()
  end
end

function M.clear()
  send('\027]21337;status=;indicator=;status-color=\007')
end

---@param kind 'busy'|'ok'|'bad'
---@param text string
function M.status(kind, text)
  generation = generation + 1
  send(('\027]21337;status=%s;indicator=%s\007'):format(text:gsub('[\\;]', '\\%0'), colors[kind]))
  if kind == 'ok' then
    local mine = generation
    vim.defer_fn(function()
      if generation == mine then
        M.clear()
      end
    end, ok_for_ms)
  end
end

---A macOS notification, but only while you're in another app or pane
---@param text string
function M.notify(text)
  if not focused then
    send(('\027]9;%s\007'):format(text))
  end
end

local function plural(n, word)
  return ('%d %s%s'):format(n, word, n == 1 and '' or 's')
end

function M.typecheck_started()
  M.status('busy', 'type-checking')
end

---@param errors integer
---@param failed boolean tsc itself couldn't run
function M.typecheck_finished(errors, failed)
  if failed then
    M.status('bad', 'type check failed')
    M.notify('The type check failed to run')
  elseif errors > 0 then
    M.status('bad', plural(errors, 'type error'))
    M.notify(plural(errors, 'type error'))
  else
    M.status('ok', 'types OK')
    M.notify('No type errors')
  end
end

---neotest consumer: plugins/test.lua registers it
---@param client neotest.Client
function M.neotest(client)
  client.listeners.run = function()
    M.status('busy', 'testing')
  end
  client.listeners.results = function(adapter_id, results, partial)
    if partial then
      return
    end
    local failed, passed = 0, 0
    for id, result in pairs(results) do
      local tree = client:get_position(id, { adapter = adapter_id })
      if tree and tree:data().type == 'test' then
        if result.status == 'failed' then
          failed = failed + 1
        elseif result.status == 'passed' then
          passed = passed + 1
        end
      end
    end
    if failed > 0 then
      M.status('bad', ('%d failing'):format(failed))
      M.notify(plural(failed, 'test') .. ' failing')
    elseif passed > 0 then
      M.status('ok', 'tests pass')
      M.notify(plural(passed, 'test') .. ' passed')
    end
  end
  return {}
end

local function regular(win)
  return vim.api.nvim_win_get_config(win).relative == '' and vim.bo[vim.api.nvim_win_get_buf(win)].buftype == ''
end

-- A window already showing the file, preferably in this tab page
local function window_showing(path)
  if vim.fn.bufexists(path) == 0 then
    return nil
  end
  local found
  for _, win in ipairs(vim.fn.win_findbuf(vim.fn.bufadd(path))) do
    if regular(win) then
      if vim.api.nvim_win_get_tabpage(win) == vim.api.nvim_get_current_tabpage() then
        return win
      end
      found = found or win
    end
  end
  return found
end

-- Not the file tree, quickfix list, a terminal or a picker
local function editor_window()
  local wins = { vim.api.nvim_get_current_win(), vim.fn.win_getid(vim.fn.winnr('#')) }
  vim.list_extend(wins, vim.api.nvim_tabpage_list_wins(0))
  for _, win in ipairs(wins) do
    if win ~= 0 and regular(win) then
      return win
    end
  end
end

---Called by bin/nvim-open over Neovim's socket
---@param path string
---@param line integer 0 when unknown
---@param col integer 0 when unknown
function M.open(path, line, col)
  local function go()
    local ok, err = pcall(function()
      local win = window_showing(path)
      if win then
        vim.api.nvim_set_current_win(win)
        if line > 0 then
          -- :edit records the jump below; here it's needed for <C-o> to come back
          vim.cmd("normal! m'")
        end
      else
        vim.api.nvim_set_current_win(editor_window() or 0)
        vim.cmd('edit ' .. vim.fn.fnameescape(path))
      end
      if line > 0 then
        line = math.min(line, vim.api.nvim_buf_line_count(0))
        vim.api.nvim_win_set_cursor(0, { line, math.max(col - 1, 0) })
        vim.cmd('normal! zz')
      end
    end)
    if not ok then
      vim.notify(tostring(err), vim.log.levels.ERROR)
    end
  end
  if vim.api.nvim_get_mode().mode:find('^[iRt]') then
    -- Leaving Insert mode moves the cursor back a column, so open after that
    vim.api.nvim_create_autocmd('ModeChanged', { pattern = '*:n*', once = true, callback = vim.schedule_wrap(go) })
    vim.cmd.stopinsert()
  else
    go()
  end
  return ''
end

function M.setup()
  local group = vim.api.nvim_create_augroup('user.iterm', { clear = true })
  vim.api.nvim_create_autocmd('FocusGained', {
    group = group,
    callback = function()
      focused = true
    end,
  })
  vim.api.nvim_create_autocmd('FocusLost', {
    group = group,
    callback = function()
      focused = false
    end,
  })
  vim.api.nvim_create_autocmd('VimLeavePre', { group = group, callback = M.clear })
  -- iTerm2 follows its profiles file by inode: saving it in place keeps
  -- iTerm2 picking up every change, not just the first
  vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufRead' }, {
    group = group,
    pattern = '*/config/iterm2/*.json',
    callback = function(args)
      vim.bo[args.buf].backupcopy = 'yes'
    end,
  })
end

return M
