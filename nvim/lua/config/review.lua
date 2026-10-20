-- Review a branch the way GitHub's "Files changed" tab shows it: every file
-- that differs from where the branch left its base, side by side with the
-- base version. The right side is the real file, so go to definition and the
-- other language server features work (in a temporary copy, imports would
-- resolve against the copy's folder instead of the project).
local M = {}

---@class review.State
---@field root string
---@field label string branch or commit the user asked to compare against
---@field base string merge-base commit
---@field tab integer
---@field left integer window with the base version
---@field files table<string, { old: string, status: string }> by absolute path
---@field group integer
local state ---@type review.State?

local labels = {
  M = 'modified',
  A = 'added',
  C = 'copied',
  T = 'type changed',
  ['?'] = 'new, not committed yet',
}

---@return string? stdout, string? stderr
local function git(root, args)
  local out = vim.system(vim.list_extend({ 'git', '-C', root }, args), { text = true }):wait()
  if out.code ~= 0 then
    return nil, vim.trim(out.stderr or '')
  end
  return out.stdout
end

-- The branch origin/HEAD points to (origin/main), else main/master
local function default_base(root)
  local head = git(root, { 'symbolic-ref', '--quiet', '--short', 'refs/remotes/origin/HEAD' })
  if head then
    return vim.trim(head)
  end
  for _, ref in ipairs({ 'origin/main', 'origin/master', 'main', 'master' }) do
    if git(root, { 'rev-parse', '--verify', '--quiet', ref }) then
      return ref
    end
  end
end

-- Files that differ from the base (committed or not), plus untracked ones
local function changed(root, base)
  local files = {}
  local parts = vim.split(git(root, { 'diff', '--name-status', '-z', '-M', base }) or '', '\0', { trimempty = true })
  local i = 1
  while i <= #parts do
    local status = parts[i]:sub(1, 1)
    if status == 'R' or status == 'C' then
      files[#files + 1] = { status = status, old = parts[i + 1], path = parts[i + 2] }
      i = i + 3
    else
      files[#files + 1] = { status = status, path = parts[i + 1] }
      i = i + 2
    end
  end
  local untracked = git(root, { 'ls-files', '--others', '--exclude-standard', '-z' }) or ''
  for _, path in ipairs(vim.split(untracked, '\0', { trimempty = true })) do
    files[#files + 1] = { status = '?', path = path }
  end
  return files
end

-- First changed line of each file, from one `git diff -U0`
local function first_lines(root, base)
  local lines, current = {}, nil
  for line in (git(root, { 'diff', '-U0', '--no-color', '-M', base }) or ''):gmatch('[^\n]+') do
    if line:sub(1, 4) == '+++ ' then
      current = line:match('^%+%+%+ b/(.+)$')
    elseif current and not lines[current] then
      local start = line:match('^@@ %-[%d,]+ %+(%d+)')
      if start then
        lines[current] = math.max(tonumber(start), 1)
      end
    end
  end
  return lines
end

local function set_left(buf)
  vim.wo[state.left].winfixbuf = false
  vim.api.nvim_win_set_buf(state.left, buf)
  vim.wo[state.left].winfixbuf = true
end

-- Show the base version of `path` next to the window showing it, in diff mode
local function show(win, path)
  local info = state.files[path]
  if not info then
    -- not part of the change (go to definition, say): no diff for it
    vim.api.nvim_win_call(win, function()
      vim.cmd('diffoff')
    end)
    vim.api.nvim_win_call(state.left, function()
      vim.cmd('diffoff')
    end)
    return
  end

  local lines = {}
  if info.status ~= 'A' and info.status ~= '?' then
    local text = git(state.root, { 'show', state.base .. ':' .. info.old })
    lines = text and vim.split(text, '\n', { plain = true }) or {}
    if lines[#lines] == '' then
      table.remove(lines)
    end
  end
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = 'wipe'
  set_left(buf)
  vim.api.nvim_buf_set_name(buf, ('review://%s/%s'):format(state.label, info.old))
  local ft = vim.filetype.match({ filename = info.old, buf = buf })
  if ft then
    vim.bo[buf].filetype = ft
  end
  for _, w in ipairs({ state.left, win }) do
    vim.api.nvim_win_call(w, function()
      vim.cmd('diffthis')
    end)
  end
end

function M.stop()
  if not state then
    return
  end
  local s = state
  state = nil
  vim.g.review = nil
  pcall(vim.api.nvim_del_augroup_by_id, s.group)
  pcall(function()
    require('gitsigns').reset_base(true)
  end)
  if vim.fn.getqflist({ title = 0 }).title:find('^Review ') then
    vim.fn.setqflist({}, 'r', { title = '', items = {} })
    vim.cmd('cclose')
  end
  if vim.api.nvim_tabpage_is_valid(s.tab) and #vim.api.nvim_list_tabpages() > 1 then
    vim.cmd.tabclose(vim.api.nvim_tabpage_get_number(s.tab))
  elseif vim.api.nvim_win_is_valid(s.left) then
    vim.cmd('diffoff!')
    vim.api.nvim_win_close(s.left, true)
  end
  vim.cmd('redrawstatus!')
end

---@param base? string branch or commit; the remote's default branch when empty
function M.start(base)
  M.stop()
  local file = vim.api.nvim_buf_get_name(0)
  local root = vim.fs.root(file ~= '' and file or vim.fn.getcwd(), '.git')
  if not root then
    vim.notify('Not in a git repository', vim.log.levels.WARN)
    return
  end
  local label = (base and base ~= '') and base or default_base(root)
  if not label then
    vim.notify("Couldn't find the default branch; name one: :Review origin/main", vim.log.levels.WARN)
    return
  end
  local merge_base = git(root, { 'merge-base', label, 'HEAD' })
  if not merge_base then
    vim.notify(('%s is not a branch or commit in this repository'):format(label), vim.log.levels.WARN)
    return
  end
  merge_base = vim.trim(merge_base)

  local files = changed(root, merge_base)
  if #files == 0 then
    vim.notify(('No changes against %s'):format(label))
    return
  end
  local first = first_lines(root, merge_base)
  local items, tracked = {}, {}
  for _, f in ipairs(files) do
    local path = vim.fs.joinpath(root, f.path)
    if f.status == 'D' then
      items[#items + 1] = { text = 'deleted: ' .. f.path }
    else
      tracked[path] = { old = f.old or f.path, status = f.status }
      items[#items + 1] = {
        filename = path,
        lnum = first[f.path] or 1,
        text = f.old and ('renamed from ' .. f.old) or labels[f.status] or f.status,
      }
    end
  end

  vim.cmd('tabnew')
  local right = vim.api.nvim_get_current_win()
  vim.cmd('leftabove vnew')
  vim.bo.bufhidden = 'wipe'
  state = {
    root = root,
    label = label,
    base = merge_base,
    tab = vim.api.nvim_get_current_tabpage(),
    left = vim.api.nvim_get_current_win(),
    files = tracked,
    group = vim.api.nvim_create_augroup('user.review', { clear = true }),
  }
  vim.wo[state.left].winfixbuf = true
  vim.g.review = label
  -- Signs, ]h and ,gp compare against the base too while reviewing
  pcall(function()
    require('gitsigns').change_base(merge_base, true)
  end)

  vim.api.nvim_create_autocmd('BufWinEnter', {
    group = state.group,
    callback = function(ev)
      local win = vim.api.nvim_get_current_win()
      if not state or vim.api.nvim_get_current_tabpage() ~= state.tab or win == state.left then
        return
      end
      if vim.bo[ev.buf].buftype ~= '' then
        return
      end
      show(win, vim.api.nvim_buf_get_name(ev.buf))
    end,
  })
  vim.api.nvim_create_autocmd('TabClosed', {
    group = state.group,
    callback = function()
      if state and not vim.api.nvim_tabpage_is_valid(state.tab) then
        M.stop()
      end
    end,
  })

  vim.api.nvim_set_current_win(right)
  vim.fn.setqflist({}, ' ', { title = ('Review against %s'):format(label), items = items })
  vim.cmd('botright copen')
  vim.cmd('cfirst')
  vim.notify(('Reviewing %d files against %s (from %s)'):format(#items, label, merge_base:sub(1, 7)))
end

function M.toggle()
  if state then
    M.stop()
  else
    M.start()
  end
end

---Branches and tags for :Review completion
function M.complete(lead)
  local root = vim.fs.root(vim.fn.getcwd(), '.git')
  local refs = root
    and git(root, { 'for-each-ref', '--format=%(refname:short)', 'refs/heads', 'refs/remotes', 'refs/tags' })
  return vim.tbl_filter(function(ref)
    return vim.startswith(ref, lead)
  end, vim.split(refs or '', '\n', { trimempty = true }))
end

return M
