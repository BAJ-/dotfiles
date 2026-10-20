-- GitHub links to the current line or selection, made by the gh CLI
local M = {}

---@return string? stdout, string? error
local function run(cmd, cwd)
  local ok, out = pcall(function()
    return vim.system(cmd, { cwd = cwd, text = true }):wait()
  end)
  if not ok then
    return nil, tostring(out)
  end
  if out.code ~= 0 then
    return nil, vim.trim(out.stderr ~= '' and out.stderr or out.stdout)
  end
  return vim.trim(out.stdout)
end

---@param copy boolean copy the link instead of opening it
function M.link(copy)
  local file = vim.api.nvim_buf_get_name(0)
  local root = file ~= '' and vim.fs.root(file, '.git') or nil
  if not root then
    vim.notify('Not a file in a git repository', vim.log.levels.WARN)
    return
  end
  local path = vim.fs.relpath(root, file)
  local first, last = vim.fn.line('.'), nil
  if vim.fn.mode():match('^[vV\22]') then
    first, last = vim.fn.line('v'), vim.fn.line('.')
    if first > last then
      first, last = last, first
    end
    vim.cmd('normal! ' .. vim.keycode('<Esc>'))
  end
  local target = ('%s:%d%s'):format(path, first, (last and last ~= first) and ('-' .. last) or '')

  local args = { 'gh', 'browse', target }
  local note
  -- A link to the commit keeps pointing at these lines; GitHub needs to have the commit
  if (run({ 'git', 'branch', '-r', '--contains', 'HEAD' }, root) or '') ~= '' then
    args[#args + 1] = '--commit'
  elseif run({ 'git', 'rev-parse', '--abbrev-ref', '@{upstream}' }, root) then
    note = "your latest commit isn't pushed, so this links to the branch and the lines may differ"
  else
    note = "this branch isn't on GitHub yet; the link works once you push"
  end
  local changed = vim.system({ 'git', 'diff', '--quiet', 'HEAD', '--', path }, { cwd = root }):wait().code == 1
  if not note and (changed or vim.bo.modified) then
    note = 'the file has changes that are not committed, so the lines may differ'
  end
  local suffix = note and (' (' .. note .. ')') or ''

  if copy then
    args[#args + 1] = '--no-browser'
    local url, err = run(args, root)
    if not url then
      vim.notify('gh browse failed: ' .. (err or ''), vim.log.levels.ERROR)
      return
    end
    vim.fn.setreg('+', url)
    vim.notify('Copied ' .. url .. suffix, note and vim.log.levels.WARN or vim.log.levels.INFO)
  else
    local _, err = run(args, root)
    if err then
      vim.notify('gh browse failed: ' .. err, vim.log.levels.ERROR)
      return
    end
    vim.notify('Opened ' .. target .. ' on GitHub' .. suffix, note and vim.log.levels.WARN or vim.log.levels.INFO)
  end
end

return M
