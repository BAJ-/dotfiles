-- package.json scripts (,pp): pick one from any package.json in the project and
-- run it in its own iTerm2 pane, below Neovim (beside the other scripts' panes),
-- while the cursor stays in Neovim. One pane per script: picking a script that's
-- still running starts nothing, and one that has finished runs again in its pane.
-- ,pl runs the last one again, and ,px closes the script panes. Needs Neovim to
-- run in iTerm2.
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

-- argv: the command to type, the pane's name, the script's tag and Neovim's own
-- session. Each script's pane carries its tag in the iTerm2 variable user.script,
-- so iTerm2 itself knows which pane in Neovim's tab runs which script, also after
-- Neovim restarts. Prints what happened: a "new" pane, ran it "again", or it's
-- still "running". (Inside the tell block "contents" is iTerm2's word for a pane's
-- text, so the script doesn't use it.)
local applescript = [[
on run argv
  set theCommand to item 1 of argv
  set theName to item 2 of argv
  set theTag to item 3 of argv
  set nvimID to item 4 of argv
  tell application "iTerm2"
    if nvimID is "" then set nvimID to unique ID of current session of current window
    repeat with w in windows
      repeat with t in tabs of w
        set nvimHere to false
        repeat with s in sessions of t
          if unique ID of s is nvimID then set nvimHere to true
        end repeat
        if nvimHere then
          set lastScript to ""
          repeat with s in sessions of t
            set paneTag to ""
            try
              tell s to set paneTag to (variable named "user.script")
            end try
            if paneTag is theTag then
              if not (is at shell prompt of s) then return "running"
              tell s to write text theCommand
              return "again"
            end if
            if paneTag is not missing value and paneTag is not "" then set lastScript to unique ID of s
          end repeat
          repeat with s in sessions of t
            if lastScript is "" and unique ID of s is nvimID then
              tell s to set newPane to (split horizontally with default profile)
              exit repeat
            else if unique ID of s is lastScript then
              tell s to set newPane to (split vertically with default profile)
              exit repeat
            end if
          end repeat
          tell newPane
            set name to theName
            set variable named "user.script" to theTag
            write text theCommand
          end tell
          repeat with s in sessions of t
            if unique ID of s is nvimID then select s
          end repeat
          return "new"
        end if
      end repeat
    end repeat
  end tell
  error "Neovim's pane wasn't found in iTerm2"
end run
]]

-- argv: Neovim's own session. Closes every pane in Neovim's tab that carries a
-- script's tag, from the last one back, so the panes still to come keep their
-- places. Prints how many it closed
local close_applescript = [[
on run argv
  set nvimID to item 1 of argv
  tell application "iTerm2"
    if nvimID is "" then set nvimID to unique ID of current session of current window
    repeat with w in windows
      repeat with t in tabs of w
        set nvimHere to false
        repeat with s in sessions of t
          if unique ID of s is nvimID then set nvimHere to true
        end repeat
        if nvimHere then
          set closed to 0
          repeat with i from (count of sessions of t) to 1 by -1
            set paneTag to ""
            try
              tell session i of t to set paneTag to (variable named "user.script")
            end try
            if paneTag is not missing value and paneTag is not "" then
              close session i of t
              set closed to closed + 1
            end if
          end repeat
          return closed as text
        end if
      end repeat
    end repeat
  end tell
  error "Neovim's pane wasn't found in iTerm2"
end run
]]

---Scripts run in an iTerm2 pane below Neovim, so Neovim has to run in iTerm2
local function in_iterm()
  if
    (vim.env.TERM_PROGRAM == 'iTerm.app' or vim.env.LC_TERMINAL == 'iTerm2') and vim.fn.executable('osascript') == 1
  then
    return true
  end
  vim.notify('Scripts run in iTerm2 panes below Neovim: ,pp needs Neovim to run in iTerm2', vim.log.levels.WARN)
  return false
end

---Runs one of the AppleScripts in the background, with Neovim's own session as
---its last value. `done` gets what it printed
---@param script string
---@param args string[]
---@param doing string what it does, for an error: "run lint"
---@param done fun(printed: string)
local function osascript(script, args, doing, done)
  local function failed(why)
    vim.notify(("Couldn't %s in iTerm2: %s"):format(doing, why), vim.log.levels.ERROR)
  end
  -- ITERM_SESSION_ID is w0t1p0:<unique ID>
  local nvim = (vim.env.ITERM_SESSION_ID or ''):match(':(.+)$') or ''
  local cmd = vim.list_extend({ 'osascript', '-' }, args)
  table.insert(cmd, nvim)
  local ok, err = pcall(vim.system, cmd, { stdin = script, text = true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        failed(vim.trim(result.stderr or ''):match('[^\n]*'))
      else
        done(vim.trim(result.stdout or ''))
      end
    end)
  end)
  if not ok then
    failed(tostring(err))
  end
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
  -- and the pane stays open with the output when the script ends
  local typed = ('cd %s && %s'):format(vim.fn.shellescape(script.dir), command(script))
  osascript(applescript, { typed, name, script.dir .. ':' .. script.name }, 'run ' .. script.name, function(printed)
    if printed == 'running' then
      vim.notify(script.name .. ' is still running, in its pane below')
    end
  end)
end

---,px: close the script panes below Neovim, stopping what still runs in them
function M.close()
  if not in_iterm() then
    return
  end
  osascript(close_applescript, {}, 'close the script panes', function(printed)
    local closed = tonumber(printed) or 0
    vim.notify(
      closed == 0 and 'No script panes to close'
        or ('Closed %d script pane%s'):format(closed, closed == 1 and '' or 's')
    )
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
