-- package.json scripts (,pp): pick one from any package.json in the project and
-- run it in its own iTerm2 pane, below Neovim (beside the other scripts' panes),
-- while the cursor stays in Neovim. One pane per script: picking a script that's
-- still running starts nothing, and one that has finished runs again in its pane.
-- ,pl runs the last one again, and ,px closes the script panes. Needs Neovim to
-- run in iTerm2, which it controls with iTerm2's own it2 command; that needs
-- iTerm2's Python API turned on (setup.sh turns it on, or tells you how).
local M = {}

---@class PackageScript
---@field name string
---@field command string what package.json runs for it
---@field dir string the package's folder
---@field file string its package.json
---@field line integer where the script is in it
---@field manager string npm, pnpm, yarn or bun

local last ---@type PackageScript?

---Every package.json in the project, from git's list of files (new ones too);
---outside a git repository, the folder's own
---@param cwd string
---@return string[] relative to cwd, the project's own first
local function package_files(cwd)
  local cmd = { 'git', 'ls-files', '-z', '--cached', '--others', '--exclude-standard', '--' }
  vim.list_extend(cmd, { ':(glob)**/package.json', ':(exclude,glob)**/node_modules/**' })
  local ok, result = pcall(function()
    return vim.system(cmd, { cwd = cwd, text = true }):wait()
  end)
  local files = (ok and result.code == 0) and vim.split(result.stdout, '\0', { plain = true, trimempty = true })
    or (vim.uv.fs_stat(vim.fs.joinpath(cwd, 'package.json')) and { 'package.json' } or {})
  table.sort(files, function(a, b)
    if (a == 'package.json') ~= (b == 'package.json') then
      return a == 'package.json'
    end
    return a < b
  end)
  return files
end

---@param cwd string
---@return PackageScript[]
local function find(cwd)
  local scripts = {}
  for _, rel in ipairs(package_files(cwd)) do
    local file = vim.fs.joinpath(cwd, rel)
    local read, lines = pcall(vim.fn.readfile, file)
    local ok, pkg = pcall(vim.json.decode, read and table.concat(lines, '\n') or '')
    if ok and type(pkg) == 'table' and type(pkg.scripts) == 'table' then
      local dir = vim.fs.dirname(file)
      local manager = require('config.debug').package_manager(dir)
      -- reading JSON loses the order of the scripts: take it, and each one's line, from the file
      local at, inside = {}, false
      for i, text in ipairs(lines) do
        inside = inside or text:find('"scripts"%s*:') ~= nil
        for name in (inside and text or ''):gmatch('"([^"]+)"%s*:') do
          if pkg.scripts[name] ~= nil and not at[name] then
            at[name] = i
          end
        end
      end
      local names = vim.tbl_filter(function(name)
        return type(pkg.scripts[name]) == 'string'
      end, vim.tbl_keys(pkg.scripts))
      table.sort(names, function(a, b)
        if (at[a] or math.huge) ~= (at[b] or math.huge) then
          return (at[a] or math.huge) < (at[b] or math.huge)
        end
        return a < b
      end)
      for _, name in ipairs(names) do
        scripts[#scripts + 1] = {
          name = name,
          command = pkg.scripts[name],
          dir = dir,
          file = file,
          line = at[name] or 1,
          manager = manager,
        }
      end
    end
  end
  return scripts
end

---"tests/e2e" for a package in a subfolder, '' for the project's own
---@param script PackageScript
---@param cwd string
local function folder_of(script, cwd)
  local rel = vim.fs.relpath(cwd, script.dir)
  return (rel and rel ~= '.') and rel or ''
end

---@param script PackageScript
---@return string like "npm run dev"
local function command(script)
  local name = script.name:match('^[%w%-_:.@/]+$') and script.name or vim.fn.shellescape(script.name)
  return ('%s run %s'):format(script.manager, name)
end

-- iTerm2's own command for controlling it: on PATH in iTerm2's sessions, else in the app
local function it2_path()
  local found = vim.fn.exepath('it2')
  if found ~= '' then
    return found
  end
  local bundled = '/Applications/iTerm.app/Contents/Resources/utilities/it2'
  return vim.fn.executable(bundled) == 1 and bundled or nil
end

---Neovim's own pane: ITERM_SESSION_ID is w0t1p0:<its ID>
local function own_pane()
  return (vim.env.ITERM_SESSION_ID or ''):match(':(.+)$')
end

---Scripts run in an iTerm2 pane below Neovim, so Neovim has to run in iTerm2
local function in_iterm()
  if not ((vim.env.TERM_PROGRAM == 'iTerm.app' or vim.env.LC_TERMINAL == 'iTerm2') and own_pane()) then
    vim.notify('Scripts run in iTerm2 panes below Neovim: ,pp needs Neovim to run in iTerm2', vim.log.levels.WARN)
  elseif not it2_path() then
    vim.notify(
      "Scripts run in iTerm2 panes through iTerm2's it2 command: ,pp needs iTerm2 3.7 or later",
      vim.log.levels.WARN
    )
  else
    return true
  end
  return false
end

---@param doing string what didn't work, for the message: "run lint"
---@param why string
local function failed(doing, why)
  vim.notify(("Couldn't %s in iTerm2: %s"):format(doing, why), vim.log.levels.ERROR)
end

---Runs iTerm2's it2 command in the background. `done` gets what it printed, or
---nil and why it failed
---@param args string[]
---@param done fun(printed: string?, why: string?)
local function it2(args, done)
  local ok, err = pcall(vim.system, vim.list_extend({ it2_path() }, args), { text = true }, function(result)
    local why = result.stderr or ''
    if why:find('Python API', 1, true) then
      why = "its Python API isn't running. In iTerm2's Settings › General › Magic, tick Enable Python API,"
        .. " or untick it and tick it again if it's ticked already"
    else
      why = vim.trim(why):gsub('^Error: ', ''):match('[^\n]*')
    end
    vim.schedule(function()
      if result.code == 0 then
        done(vim.trim(result.stdout or ''))
      else
        done(nil, why ~= '' and why or ('it2 stopped with code ' .. result.code))
      end
    end)
  end)
  if not ok then
    vim.schedule(function()
      done(nil, tostring(err))
    end)
  end
end

---For an it2 call that only has something to say when it fails
---@param doing string
local function or_fail(doing)
  return function(_, why)
    if why then
      failed(doing, why)
    end
  end
end

-- For each pane iTerm2 fills in what runs in it, a tab, and the script the pane
-- was opened for: each script's pane carries its tag in the iTerm2 variable
-- user.script, so iTerm2 itself knows which pane runs which script, also after
-- Neovim restarts
local list = { 'session', 'list', '--json', '--format', '\\(session.jobName)\\t\\(user.script)' }

---@class ScriptPane
---@field id string
---@field tag string the script it runs, '' for other panes
---@field running boolean something other than your shell runs in it

---The panes in Neovim's tab, in iTerm2's order
---@param doing string
---@param done fun(nvim: string, panes: ScriptPane[])
local function panes(doing, done)
  local nvim = own_pane() --[[@as string]]
  it2(list, function(printed, why)
    local ok, all = pcall(vim.json.decode, printed or '')
    if not ok or type(all) ~= 'table' then
      return failed(doing, why or "iTerm2's list of panes couldn't be read")
    end
    local tab
    for _, pane in ipairs(all) do
      if pane.id == nvim then
        tab = pane.tab_id
      end
    end
    if not tab then
      return failed(doing, "Neovim's pane wasn't found in iTerm2")
    end
    -- at its prompt, a pane runs your shell
    local shell = vim.fs.basename(vim.env.SHELL or 'zsh')
    local found = {}
    for _, pane in ipairs(all) do
      if pane.tab_id == tab then
        local job, tag = tostring(pane.formatted or ''):match('^([^\t]*)\t(.*)$')
        found[#found + 1] = { id = pane.id, tag = tag or '', running = job ~= shell }
      end
    end
    done(nvim, found)
  end)
end

---@param script PackageScript
function M.run(script)
  if not in_iterm() then
    return
  end
  last = script
  local cwd = vim.fn.getcwd()
  local folder = folder_of(script, cwd)
  local name = ('%s · %s'):format(script.name, vim.fs.basename(cwd) .. (folder ~= '' and ('/' .. folder) or ''))
  -- typed into the pane's shell, so your shell setup (and fnm's Node) loads first
  -- and the pane stays open with the output when the script ends. The cd is a line
  -- of its own: iTerm2 learns a pane's folder at each prompt, and finds the files
  -- the script prints, for ⌘-click, from there
  local typed = ('cd %s\r%s'):format(vim.fn.shellescape(script.dir), command(script))
  local tag = script.dir .. ':' .. script.name
  local doing = 'run ' .. script.name
  panes(doing, function(nvim, found)
    local beside -- the last script's pane: a new one goes beside it, else below Neovim
    for _, pane in ipairs(found) do
      if pane.tag == tag then
        if pane.running then
          vim.notify(script.name .. ' is still running, in its pane below')
        else
          it2({ 'session', 'run', typed, '--session', pane.id }, or_fail(doing))
        end
        return
      end
      if pane.tag ~= '' then
        beside = pane.id
      end
    end
    local split = { 'session', 'split', '--session', beside or nvim }
    if beside then
      split[#split + 1] = '--vertical'
    end
    it2(split, function(printed, why)
      local new = printed and printed:match('Created new pane: (%S+)')
      if not new then
        return failed(doing, why or printed)
      end
      -- splitting the pane you're in takes you to the new pane; splitting another doesn't
      if not beside then
        it2({ 'session', 'focus', nvim }, or_fail(doing))
      end
      -- iTerm2 reads the value as JSON
      it2({ 'session', 'set-var', 'user.script', vim.json.encode(tag), '--session', new }, or_fail(doing))
      it2({ 'session', 'set-name', name, '--session', new }, or_fail(doing))
      it2({ 'session', 'run', typed, '--session', new }, or_fail(doing))
    end)
  end)
end

---,px: close the script panes below Neovim, stopping what still runs in them
function M.close()
  if not in_iterm() then
    return
  end
  local doing = 'close the script panes'
  panes(doing, function(_, found)
    local scripts = vim.tbl_filter(function(pane)
      return pane.tag ~= ''
    end, found)
    if #scripts == 0 then
      return vim.notify('No script panes to close')
    end
    local left, closed, why = #scripts, 0, nil
    for _, pane in ipairs(scripts) do
      -- --force, or it2 asks first, which Neovim can't answer. iTerm2 itself still
      -- asks about a running script if your settings say so
      it2({ 'session', 'close', '--force', '--session', pane.id }, function(printed, failure)
        closed, why, left = closed + (printed and 1 or 0), why or failure, left - 1
        if left > 0 then
          return
        end
        if closed == #scripts then
          vim.notify(('Closed %d script pane%s'):format(closed, closed == 1 and '' or 's'))
        else
          vim.notify(('Closed %d of %d script panes: %s'):format(closed, #scripts, why), vim.log.levels.WARN)
        end
      end)
    end
  end)
end

---,pl
function M.run_last()
  if last then
    M.run(last)
  else
    vim.notify('No script has run yet: ,pp picks one')
  end
end

---,pp: every script in the project, with its package.json beside it
function M.pick()
  if not in_iterm() then
    return
  end
  local cwd = vim.fn.getcwd()
  local scripts = find(cwd)
  if #scripts == 0 then
    vim.notify('No package.json scripts in this folder')
    return
  end
  require('config.fzf').setup()
  local fzf = require('fzf-lua')
  local function dim(text)
    return (fzf.utils.ansi_from_hl('Comment', text))
  end
  local name_width, folder_width = 0, 0
  for _, script in ipairs(scripts) do
    name_width = math.max(name_width, vim.fn.strdisplaywidth(script.name))
    folder_width = math.max(folder_width, vim.fn.strdisplaywidth(folder_of(script, cwd)))
  end
  local function pad(text, width)
    return text .. (' '):rep(width - vim.fn.strdisplaywidth(text) + 2)
  end
  -- each entry starts with the script's place in its package.json, for the
  -- preview, then a tab and what the list shows
  local entries, by_place = {}, {}
  for _, script in ipairs(scripts) do
    local place = ('%s:%d:1:%s'):format(script.file, script.line, script.name)
    by_place[place] = script
    local folder = folder_width > 0 and dim(pad(folder_of(script, cwd), folder_width)) or ''
    entries[#entries + 1] = place .. '\t' .. pad(script.name, name_width) .. folder .. dim(script.command)
  end
  fzf.fzf_exec(entries, {
    prompt = 'Scripts> ',
    previewer = 'builtin',
    fzf_opts = { ['--delimiter'] = '\t', ['--with-nth'] = '2..' },
    actions = {
      ['enter'] = function(selected)
        local script = selected[1] and by_place[selected[1]:match('^[^\t]+')]
        if script then
          M.run(script)
        end
      end,
    },
  })
end

return M
