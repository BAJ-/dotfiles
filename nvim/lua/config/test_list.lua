-- The test list (,mt): every Vitest/Jest and Playwright test in the project, in a
-- panel on the right with an area for each. Check tests with Space and run them
-- with r, without opening their files. Vitest and Jest tests come from neotest
-- and run through it, with their results; Playwright's come from Playwright's own
-- list, read again in the background, and run in the terminal below like ,ma.
-- Watched files are marked, and w starts or stops watching.
local M = {}

local project_tests = require('config.project_tests')
local playwright = require('config.playwright')

local ns = vim.api.nvim_create_namespace('user.test_list')
local group = vim.api.nvim_create_augroup('user.test_list', { clear = true })

local client ---@type neotest.Client? set once neotest is set up (plugins/test.lua)
local buf ---@type integer?
local win ---@type integer?
local origin ---@type integer? the window the list was opened from: tests open there

---@class TestListItem
---@field key string
---@field kind 'unit'|'playwright'
---@field type 'file'|'namespace'|'test'
---@field name string
---@field path string
---@field line? integer
---@field id? string neotest position (Vitest, Jest)
---@field adapter? string neotest adapter
---@field status? 'passed'|'failed'|'skipped'|'running'
---@field children TestListItem[]
---@field tests? TestListItem[] the tests under it, or itself when there are none

---@class TestListArea
---@field kind 'unit'|'playwright'
---@field title string
---@field root? string the Playwright folder
---@field files? TestListItem[]
---@field note? string
---@field error? boolean

---@class TestListLine
---@field chunks {[1]: string, [2]: string?}[]
---@field right? {[1]: string, [2]: string?}[] shown at the right edge
---@field flex? integer the chunk to shorten when the line is too long
---@field flex_left? boolean shorten it from the left (paths keep their file name)
---@field item? TestListItem
---@field area? TestListArea
---@field header? boolean the area's title
---@field open? boolean a file that shows its tests
---@field tests? TestListItem[] what Space checks here: the tests on show under this line

-- What's checked, open, closed and filtered, per project folder, while Neovim runs.
-- open[file] is false once you close a file that a filter opened
---@class TestListState
---@field checked table<string, true>
---@field open table<string, boolean>
---@field collapsed table<string, true> areas, by Playwright folder or 'unit'
---@field filter? string
---@field help boolean
---@type table<string, TestListState>
local projects = {}

---@return TestListState
local function state()
  local cwd = vim.fn.getcwd()
  projects[cwd] = projects[cwd] or { checked = {}, open = {}, collapsed = {}, help = false }
  return projects[cwd]
end

-- Vitest and Jest files per project folder, as neotest last reported them
---@type table<string, {files: TestListItem[], roots: table<string, string>, error?: string}>
local unit = {}
-- Playwright's tests per Playwright folder
---@type table<string, {files?: TestListItem[], error?: string, reading?: boolean, again?: boolean}>
local pw = {}

local lines = {} ---@type TestListLine[] what each line of the list shows
local areas = {} ---@type TestListArea[]

local function visible()
  return win ~= nil and vim.api.nvim_win_is_valid(win) and buf ~= nil and vim.api.nvim_win_get_buf(win) == buf
end

---@param item TestListItem
---@return TestListItem[]
local function tests_of(item)
  if not item.tests then
    local tests = {}
    local function walk(it)
      if it.type == 'test' or #it.children == 0 then
        tests[#tests + 1] = it
      else
        for _, child in ipairs(it.children) do
          walk(child)
        end
      end
    end
    walk(item)
    item.tests = tests
  end
  return item.tests
end

---@return integer checked, integer total
local function count(item, checked)
  local tests = tests_of(item)
  local n = 0
  for _, test in ipairs(tests) do
    n = n + (checked[test.key] and 1 or 0)
  end
  return n, #tests
end

---@param item TestListItem
---@param fn fun(item: TestListItem): boolean?
local function any(item, fn)
  if fn(item) then
    return true
  end
  for _, child in ipairs(item.children) do
    if any(child, fn) then
      return true
    end
  end
  return false
end

local function watching(item)
  local nt = package.loaded.neotest
  return item.kind == 'unit' and nt ~= nil and nt.watch ~= nil and nt.watch.is_watching(item.id)
end

---Vitest and Jest files, from neotest. Runs in neotest's async context
---@param cwd string
local function read_unit_files(cwd)
  local files, roots = {}, {}
  assert(client)
  for _, adapter in ipairs(client:get_adapters()) do
    local tree = client:get_position(nil, { adapter = adapter })
    if tree then
      roots[adapter] = tree:data().id
      local results = client:get_results(adapter) or {}
      ---@return TestListItem
      local function item(pos)
        local result = results[pos.id]
        return {
          key = 'u:' .. pos.id,
          kind = 'unit',
          type = pos.type,
          name = pos.name,
          path = pos.path,
          id = pos.id,
          adapter = adapter,
          line = pos.range and pos.range[1] + 1,
          status = client:is_running(pos.id, { adapter = adapter }) and 'running' or (result and result.status),
          children = {},
        }
      end
      local function add_children(node, parent)
        for _, child in ipairs(node:children()) do
          local it = item(child:data())
          parent.children[#parent.children + 1] = it
          add_children(child, it)
        end
      end
      for _, node in tree:iter_nodes() do
        if node:data().type == 'file' then
          local file = item(node:data())
          file.name = vim.fs.relpath(cwd, file.path) or file.path
          add_children(node, file)
          files[#files + 1] = file
        end
      end
    end
  end
  table.sort(files, function(a, b)
    return a.name < b.name
  end)
  return files, roots
end

local reading_unit, read_unit_again = false, false

local function refresh_unit()
  if not client then
    return
  end
  if reading_unit then
    read_unit_again = true
    return
  end
  reading_unit = true
  local cwd = vim.fn.getcwd()
  require('nio').run(function()
    local ok, files, roots = pcall(read_unit_files, cwd)
    vim.schedule(function()
      reading_unit = false
      unit[cwd] = ok and { files = files, roots = roots }
        or { files = {}, roots = {}, error = 'neotest failed: ' .. tostring(files):match('[^\n]*') }
      M.draw()
      if read_unit_again then
        read_unit_again = false
        refresh_unit()
      end
    end)
  end)
end

---@param root string the Playwright folder
---@param data table Playwright's JSON report
---@return TestListItem[]
local function playwright_files(root, data)
  local base = (data.config or {}).rootDir or root
  local files = {}
  for _, suite in ipairs(data.suites or {}) do
    local path = vim.fs.normalize(vim.fs.joinpath(base, suite.file))
    ---@type TestListItem
    local file = {
      key = 'p:' .. path,
      kind = 'playwright',
      type = 'file',
      name = vim.fs.relpath(root, path) or path,
      path = path,
      line = 1,
      children = {},
    }
    -- specs (tests) and suites (describe blocks) come in two lists: put them back in file order
    local function add(s, parent, titles)
      local entries = {}
      for _, spec in ipairs(s.specs or {}) do
        entries[#entries + 1] = { node = spec, type = 'test' }
      end
      for _, child in ipairs(s.suites or {}) do
        entries[#entries + 1] = { node = child, type = 'namespace' }
      end
      for i, entry in ipairs(entries) do
        entry.order = i
      end
      table.sort(entries, function(a, b)
        if a.node.line ~= b.node.line then
          return (a.node.line or 0) < (b.node.line or 0)
        end
        return a.order < b.order
      end)
      for _, entry in ipairs(entries) do
        local path_titles = vim.list_extend(vim.list_slice(titles), { entry.node.title })
        ---@type TestListItem
        local it = {
          key = 'p:' .. path .. '::' .. table.concat(path_titles, '::'),
          kind = 'playwright',
          type = entry.type,
          name = entry.node.title,
          path = path,
          line = entry.node.line,
          children = {},
        }
        parent.children[#parent.children + 1] = it
        if entry.type == 'namespace' then
          add(entry.node, it, path_titles)
        end
      end
    end
    add(suite, file, {})
    files[#files + 1] = file
  end
  table.sort(files, function(a, b)
    return a.name < b.name
  end)
  return files
end

---Playwright lists its tests itself (it knows its config, projects and test
---folders) into a file: its normal output can have other things in it
---@param root string
local function read_playwright(root)
  local entry = pw[root] or {}
  pw[root] = entry
  if entry.reading then
    entry.again = true
    return
  end
  local binary = playwright.binary(root)
  if not binary then
    entry.error = "Playwright isn't installed here: run npm install in "
      .. (vim.fs.relpath(vim.fn.getcwd(), root) or root)
    M.draw()
    return
  end
  entry.reading = true
  local out = vim.fn.tempname() .. '.json'
  local ok = pcall(vim.system, { binary, 'test', '--list', '--reporter=json' }, {
    cwd = root,
    env = { PLAYWRIGHT_JSON_OUTPUT_NAME = out },
    text = true,
    timeout = 120000,
  }, function(result)
    vim.schedule(function()
      entry.reading = false
      local fd = io.open(out)
      local decoded, data = pcall(vim.json.decode, fd and fd:read('*a') or '')
      if fd then
        fd:close()
      end
      os.remove(out)
      if decoded and type(data) == 'table' and data.suites then
        entry.files = playwright_files(root, data)
        -- a spec that doesn't load is left out of the list; say which
        local errors = data.errors or {}
        entry.error = #errors > 0 and ('Playwright: ' .. tostring(errors[1].message):match('[^\n]*')) or nil
      else
        local why = (result.stderr or ''):match('%S[^\n]*')
        entry.error = "Playwright couldn't list its tests" .. (why and (': ' .. why) or '')
      end
      M.draw()
      if entry.again then
        entry.again = false
        read_playwright(root)
      end
    end)
  end)
  if not ok then
    entry.reading = false
    entry.error = "Couldn't start Playwright"
    M.draw()
  end
end

---@param cwd string
---@param tests ProjectTests
---@return TestListArea[]
local function areas_for(cwd, tests)
  local list = {}
  local unit_name = project_tests.unit_name(tests)
  if unit_name then
    local data = unit[cwd]
    ---@type TestListArea
    local area = { kind = 'unit', title = unit_name }
    if not data then
      area.note = 'Reading the tests…'
    elseif data.error then
      area.note, area.error = data.error, true
    elseif #data.files == 0 then
      area.note = 'No test files found'
    else
      area.files = data.files
    end
    list[#list + 1] = area
  end
  for _, root in ipairs(tests.playwright) do
    local entry = pw[root] or {}
    local rel = vim.fs.relpath(cwd, root)
    ---@type TestListArea
    local area = {
      kind = 'playwright',
      root = root,
      title = (rel and rel ~= '.') and ('Playwright (%s)'):format(rel) or 'Playwright',
      files = entry.files,
    }
    if entry.error then
      area.note, area.error = entry.error, true
    elseif not entry.files then
      area.note = "Reading Playwright's list of tests…"
    elseif #entry.files == 0 then
      area.note = 'No tests found'
    end
    list[#list + 1] = area
  end
  return list
end

---Every word of the filter has to appear in a test's file path, describe blocks
---or name; lowercase words match either case, as with Vim's smartcase
---@param filter? string
---@return (fun(text: string): boolean)?
local function matcher(filter)
  local words = vim.split(filter or '', '%s+', { trimempty = true })
  if #words == 0 then
    return nil
  end
  local exact = filter:find('%u') ~= nil
  return function(text)
    text = exact and text or text:lower()
    for _, word in ipairs(words) do
      if not text:find(exact and word or word:lower(), 1, true) then
        return false
      end
    end
    return true
  end
end

---What a filter leaves of a file: true when its path matches (all of it shows),
---or the describe blocks and tests that match, or nil when nothing does
---@param file TestListItem
---@param matches fun(text: string): boolean
---@return true|table<TestListItem, true>|nil
local function filter_file(file, matches)
  if matches(file.name) then
    return true
  end
  local shown, found = {}, false
  local function walk(item, trail)
    local text = trail .. ' ' .. item.name
    local show = matches(text)
    for _, child in ipairs(item.children) do
      show = walk(child, text) or show
    end
    if show then
      shown[item], found = true, true
    end
    return show
  end
  for _, child in ipairs(file.children) do
    walk(child, file.name)
  end
  return found and shown or nil
end

---The tests under `item` that are on show
---@param item TestListItem
---@param shown true|table<TestListItem, true>
---@return TestListItem[]
local function shown_tests(item, shown)
  if shown == true then
    return tests_of(item)
  end
  return vim.tbl_filter(function(test)
    return shown[test] == true
  end, tests_of(item))
end

local status_icons = {
  passed = { '✓', 'DiagnosticOk' },
  failed = { '✗', 'DiagnosticError' },
  skipped = { '○', 'Comment' },
  running = { '…', 'DiagnosticWarn' },
}

---A closed area shows whether something in it is running or failed
---@param files TestListItem[]
---@return string?
local function area_status(files)
  local failed = false
  for _, file in ipairs(files) do
    if any(file, function(it)
      return it.status == 'running'
    end) then
      return 'running'
    end
    failed = failed or any(file, function(it)
      return it.status == 'failed'
    end)
  end
  return failed and 'failed' or nil
end

---@param item TestListItem
---@param open boolean false for a closed file: it shows what happens inside it
local function right_of(item, open)
  local right = {}
  if any(item, function(it)
    return (it == item or not open) and watching(it)
  end) then
    right[#right + 1] = { ' watching ', 'DiagnosticInfo' }
  end
  local status = item.status
  if not open and any(item, function(it)
    return it.status == 'running'
  end) then
    status = 'running'
  end
  if status_icons[status] then
    right[#right + 1] = status_icons[status]
  end
  return right
end

---@param item TestListItem
local function box(item, checked)
  local n, total = count(item, checked)
  if n == 0 then
    return { '☐', 'Comment' }
  end
  return { n == total and '☑' or '◩', 'Special' }
end

local help = {
  { 'Space', 'check or uncheck it, or all on show under it' },
  { 'Enter', 'open or close a file or area, or go to a test' },
  { '/', 'filter as you type; Esc removes the filter' },
  { 'r', 'run the checked tests' },
  { 'a', 'run all tests in this area, or all on show' },
  { 'i', 'go to the test or file' },
  { 'o', "show the test's output (Vitest and Jest)" },
  { 'w', 'watch it (run on every save), or stop' },
  { 'c', 'uncheck everything' },
  { 'q', 'close the list; ,mt opens it again' },
}

---Shortens the line's flexible part so it fits, and its right side stays visible
---@param line TestListLine
---@param width integer
local function fit(line, width)
  local used = 0
  for _, chunk in ipairs(line.chunks) do
    used = used + vim.fn.strdisplaywidth(chunk[1])
  end
  for _, chunk in ipairs(line.right or {}) do
    used = used + vim.fn.strdisplaywidth(chunk[1])
  end
  local over = used + 2 - width
  local flex = line.flex and line.chunks[line.flex]
  if over <= 0 or not flex or flex[1] == '' then
    return
  end
  local text = flex[1]
  local keep = vim.fn.strchars(text) - over - 1
  if keep < 1 then
    flex[1] = '…'
  elseif line.flex_left then
    flex[1] = '…' .. vim.fn.strcharpart(text, vim.fn.strchars(text) - keep)
  else
    flex[1] = vim.fn.strcharpart(text, 0, keep) .. '…'
  end
end

---@param line TestListLine
local function key_of(line)
  return line.item and line.item.key or (line.header and ('area:' .. (line.area.root or line.area.kind)))
end

---@param s TestListState
local function winbar(s)
  local bar = ' %#Title#Tests%*  '
  if s.filter then
    return bar .. '%#Comment#filter:%* %#Special#' .. (s.filter:gsub('%%', '%%%%')) .. '%*  %#Comment#Esc removes it%*'
  end
  return bar .. '%#Comment#? shows the keys%*'
end

function M.draw()
  if not (buf and vim.api.nvim_buf_is_valid(buf)) then
    return
  end
  local s = state()
  local width = visible() and vim.api.nvim_win_get_width(win) or 60
  local new = {} ---@type TestListLine[]
  local function add(chunks, line)
    line = line or {}
    line.chunks = chunks
    new[#new + 1] = line
  end

  if s.help then
    for _, row in ipairs(help) do
      add({ { ('  %-6s'):format(row[1]), 'Special' }, { row[2] } }, { flex = 2 })
    end
    add({})
  end

  local cwd = vim.fn.getcwd()
  local tests = project_tests.get(cwd)
  local matches = matcher(s.filter)
  areas = tests and areas_for(cwd, tests) or {}
  if not tests then
    add({ { '  Looking for tests…', 'Comment' } })
  elseif #areas == 0 then
    add({ { '  No Vitest, Jest or Playwright tests in this folder', 'Comment' } })
  end
  for i, area in ipairs(areas) do
    if i > 1 then
      add({})
    end
    local collapsed = s.collapsed[area.root or area.kind]
    local files = {} ---@type {file: TestListItem, shown: true|table<TestListItem, true>}[]
    local area_tests = {}
    for _, file in ipairs(area.files or {}) do
      local shown = not matches or filter_file(file, matches)
      if shown then
        files[#files + 1] = { file = file, shown = shown }
        vim.list_extend(area_tests, shown_tests(file, shown))
      end
    end
    local right = {}
    if area.files then
      local checked = 0
      for _, file in ipairs(area.files) do
        checked = checked + count(file, s.checked)
      end
      local total = #area.files == 1 and '1 file' or ('%d files'):format(#area.files)
      right[1] = {
        (matches and ('%d of %s'):format(#files, total) or total)
          .. (checked > 0 and (' · %d checked'):format(checked) or ''),
        'Comment',
      }
      local status = collapsed and area_status(area.files)
      if status then
        right[2] = { ' ' .. status_icons[status][1], status_icons[status][2] }
      end
    end
    add(
      { { ' ' .. (collapsed and '▸' or '▾') .. ' ', 'Comment' }, { area.title, 'Title' } },
      { area = area, header = true, right = right, tests = area_tests }
    )
    if not collapsed then
      if area.note then
        add({ { '   ' .. area.note, area.error and 'DiagnosticError' or 'Comment' } }, { area = area })
      end
      if matches and area.files and #files == 0 then
        add({ { '   No matches', 'Comment' } }, { area = area })
      end
    end
    for _, entry in ipairs(collapsed and {} or files) do
      local file, shown = entry.file, entry.shown
      -- a filter that matches tests rather than the file's path opens the file to show them
      local open = #file.children > 0 and (s.open[file.key] == true or (shown ~= true and s.open[file.key] ~= false))
      local fold = #file.children == 0 and ' ' or open and '▾' or '▸'
      local dir, name = file.name:match('^(.*/)([^/]+)$')
      local chunks = {
        { ' ' .. fold .. ' ', 'Comment' },
        box(file, s.checked),
        { ' ' },
        { dir or '', 'Comment' },
        { name or file.name },
      }
      add(chunks, {
        item = file,
        area = area,
        open = open,
        right = right_of(file, open),
        flex = 4,
        flex_left = true,
        tests = shown_tests(file, shown),
      })
      local function rows(parent, depth)
        for _, child in ipairs(parent.children) do
          if shown == true or shown[child] then
            add({
              { ('  '):rep(depth + 1) },
              box(child, s.checked),
              { ' ' .. child.name, child.type == 'namespace' and 'Type' or nil },
            }, {
              item = child,
              area = area,
              right = right_of(child, true),
              flex = 3,
              tests = shown_tests(child, shown),
            })
            rows(child, depth + 1)
          end
        end
      end
      if open then
        rows(file, 1)
      end
    end
  end

  -- keep the cursor on the same test while the list changes around it
  local cursor, cursor_key
  if visible() then
    cursor = vim.api.nvim_win_get_cursor(win)
    cursor_key = lines[cursor[1]] and key_of(lines[cursor[1]])
  end

  local text, highlights = {}, {}
  for row, line in ipairs(new) do
    fit(line, width)
    local parts, col = {}, 0
    for _, chunk in ipairs(line.chunks) do
      parts[#parts + 1] = chunk[1]
      if chunk[2] and #chunk[1] > 0 then
        highlights[#highlights + 1] = { row - 1, col, col + #chunk[1], chunk[2] }
      end
      col = col + #chunk[1]
    end
    text[row] = table.concat(parts)
  end
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, text)
  vim.bo[buf].modifiable = false
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for _, hl in ipairs(highlights) do
    vim.api.nvim_buf_set_extmark(buf, ns, hl[1], hl[2], { end_col = hl[3], hl_group = hl[4] })
  end
  for row, line in ipairs(new) do
    if line.right and #line.right > 0 then
      vim.api.nvim_buf_set_extmark(buf, ns, row - 1, 0, { virt_text = line.right, virt_text_pos = 'right_align' })
    end
  end
  lines = new
  if visible() then
    vim.wo[win][0].winbar = winbar(s)
  end

  if cursor_key then
    for row, line in ipairs(lines) do
      if key_of(line) == cursor_key then
        pcall(vim.api.nvim_win_set_cursor, win, { row, cursor[2] })
        break
      end
    end
  end
end

local timer ---@type uv.uv_timer_t?

---Read neotest's tests and results again, at most every 150ms
function M.refresh_soon()
  if not visible() then
    return
  end
  timer = timer or assert(vim.uv.new_timer())
  if not timer:is_active() then
    timer:start(150, 0, vim.schedule_wrap(refresh_unit))
  end
end

---Read everything again: the project's kinds of tests, neotest's and Playwright's
function M.refresh()
  local cwd = vim.fn.getcwd()
  project_tests.when_ready(cwd, function(tests)
    if not visible() or vim.fn.getcwd() ~= cwd then
      return
    end
    if project_tests.unit_name(tests) then
      require('plugins.test').setup()
      refresh_unit()
    end
    for _, root in ipairs(tests.playwright) do
      read_playwright(root)
    end
    M.draw()
  end)
  M.draw()
end

---After watching starts or stops somewhere else (,mw): neotest sets it up in the background
function M.watching_changed()
  for _, ms in ipairs({ 500, 2000 }) do
    vim.defer_fn(function()
      if visible() then
        M.draw()
      end
    end, ms)
  end
end

---@return TestListLine?
local function current()
  return lines[vim.api.nvim_win_get_cursor(0)[1]]
end

---@param tests TestListItem[]
local function toggle(tests)
  local checked = state().checked
  local all = #tests > 0
  for _, test in ipairs(tests) do
    if not checked[test.key] then
      all = false
      break
    end
  end
  for _, test in ipairs(tests) do
    checked[test.key] = (not all) or nil
  end
  M.draw()
end

local function check()
  local line = current()
  toggle(line and line.tests or {})
end

local function check_selection()
  local from, to = vim.fn.line('v'), vim.fn.line('.')
  if from > to then
    from, to = to, from
  end
  local tests = {}
  for row = from, to do
    vim.list_extend(tests, lines[row] and lines[row].tests or {})
  end
  vim.api.nvim_feedkeys(vim.keycode('<Esc>'), 'nx', false)
  toggle(tests)
end

---A window for code: the one the list was opened from, another one, or a new one
---@return integer
local function code_window()
  if origin and origin ~= win and vim.api.nvim_win_is_valid(origin) then
    return origin
  end
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if
      w ~= win
      and vim.api.nvim_win_get_config(w).relative == ''
      and vim.bo[vim.api.nvim_win_get_buf(w)].buftype == ''
    then
      return w
    end
  end
  return vim.api.nvim_open_win(vim.api.nvim_create_buf(true, false), false, { split = 'left', win = -1 })
end

---@param item TestListItem
local function go_to(item)
  origin = code_window()
  vim.api.nvim_set_current_win(origin)
  vim.cmd.edit(vim.fn.fnameescape(item.path))
  if item.line then
    pcall(vim.api.nvim_win_set_cursor, origin, { item.line, 0 })
    vim.cmd('normal! zvzz')
  end
end

local function enter()
  local line = current()
  if line and line.header then
    local collapsed = state().collapsed
    local key = line.area.root or line.area.kind
    collapsed[key] = not collapsed[key] or nil
    M.draw()
    return
  end
  local item = line and line.item
  if not item then
    return
  end
  if item.type == 'file' and #item.children > 0 then
    state().open[item.key] = not line.open
    M.draw()
  else
    go_to(item)
  end
end

---The smallest set of runs that covers the selected tests: a whole file or
---describe block when all of it is selected
---@param item TestListItem
---@param selected table<string, true>
---@param out TestListItem[]
local function runs(item, selected, out)
  local n, total = count(item, selected)
  if n == total and n > 0 then
    out[#out + 1] = item
  elseif n > 0 then
    for _, child in ipairs(item.children) do
      runs(child, selected, out)
    end
  end
end

---Runs the selected tests of these areas; ,ml runs them again
---@param selected table<string, true> test keys
---@param list TestListArea[]
---@return boolean ran false when nothing was selected
local function run_selected(selected, list)
  local unit_runs, groups, by_root = {}, {}, {}
  for _, area in ipairs(list) do
    for _, file in ipairs(area.files or {}) do
      local out = {}
      runs(file, selected, out)
      for _, item in ipairs(out) do
        if area.kind == 'unit' then
          unit_runs[#unit_runs + 1] = item
        else
          if not by_root[area.root] then
            by_root[area.root] = { dir = area.root, args = { 'test' } }
            groups[#groups + 1] = by_root[area.root]
          end
          -- Playwright reads file arguments as patterns; file:line picks a test or describe block
          local file = require('config.debug').regex_escape(vim.uv.fs_realpath(item.path) or item.path)
          table.insert(by_root[area.root].args, item.type == 'file' and file or ('%s:%d'):format(file, item.line))
        end
      end
    end
  end
  if #unit_runs == 0 and #groups == 0 then
    return false
  end
  local function start()
    for _, item in ipairs(unit_runs) do
      require('neotest').run.run({ item.id, adapter = item.adapter })
    end
    if #groups > 0 then
      playwright.run_many(groups)
    end
  end
  start()
  require('plugins.test').rerun_with(start)
  return true
end

local function run_checked()
  if not run_selected(state().checked, areas) then
    vim.notify('Nothing is checked: press Space on a test or a file first', vim.log.levels.WARN)
  end
end

---@return TestListArea?
local function area_here()
  for row = vim.api.nvim_win_get_cursor(0)[1], 1, -1 do
    if lines[row] and lines[row].area then
      return lines[row].area
    end
  end
  return areas[1]
end

local function run_area()
  local area = area_here()
  if not area then
    return
  end
  if state().filter then
    -- what the filter shows of the area, which its title line knows
    local selected = {}
    for _, line in ipairs(lines) do
      if line.header and line.area == area then
        for _, test in ipairs(line.tests or {}) do
          selected[test.key] = true
        end
      end
    end
    if not run_selected(selected, { area }) then
      vim.notify('Nothing in ' .. area.title .. ' matches the filter', vim.log.levels.WARN)
    end
    return
  end
  local start
  if area.kind == 'playwright' then
    start = function()
      playwright.run({ 'test' }, area.root)
    end
  else
    local data = unit[vim.fn.getcwd()]
    local roots = data and data.roots or {}
    start = function()
      for adapter, root in pairs(roots) do
        require('neotest').run.run({ root, adapter = adapter })
      end
    end
  end
  start()
  require('plugins.test').rerun_with(start)
end

---Filters the list as you type, at the command line: Enter keeps the filter, Esc removes it
local function filter()
  local s = state()
  local function set(text)
    s.filter = vim.trim(text) ~= '' and text or nil
  end
  local live = vim.api.nvim_create_autocmd('CmdlineChanged', {
    group = group,
    callback = function()
      if vim.fn.getcmdtype() == '@' then
        set(vim.fn.getcmdline())
        M.draw()
        vim.cmd.redraw()
      end
    end,
  })
  -- Esc gives back a line break, which can't be typed at the prompt
  local ok, text = pcall(vim.fn.input, { prompt = 'Filter: ', default = s.filter or '', cancelreturn = '\n' })
  vim.api.nvim_del_autocmd(live)
  set((ok and text ~= '\n') and text or '')
  M.draw()
  for row, line in ipairs(s.filter and lines or {}) do
    if line.item then
      vim.api.nvim_win_set_cursor(0, { row, 0 })
      break
    end
  end
end

local function output()
  local line = current()
  local item = line and line.item
  if not item then
    return
  end
  if item.kind == 'playwright' then
    vim.notify("Playwright's output is in its terminal, below the code")
    return
  end
  require('neotest').output.open({ position_id = item.id, adapter = item.adapter, enter = true })
end

local function watch()
  local line = current()
  local item = line and line.item
  if not item then
    return
  end
  if item.kind == 'playwright' then
    vim.notify('Watching works for Vitest and Jest tests', vim.log.levels.WARN)
    return
  end
  local nt = require('neotest')
  if nt.watch.is_watching(item.id) then
    nt.watch.stop(item.id)
    M.draw()
    return
  end
  local function start()
    nt.watch.watch({ item.id, adapter = item.adapter })
    M.watching_changed()
  end
  local file = vim.fn.bufadd(item.path)
  if #vim.lsp.get_clients({ bufnr = file }) > 0 then
    start()
    return
  end
  -- neotest finds what a test depends on through the language server, which only
  -- works on open files: open this one in the background first
  local started = false
  local attached = vim.api.nvim_create_autocmd('LspAttach', {
    buffer = file,
    once = true,
    callback = function()
      started = true
      vim.schedule(start)
    end,
  })
  vim.fn.bufload(file)
  vim.bo[file].buflisted = true
  if vim.bo[file].filetype == '' then
    vim.api.nvim_buf_call(file, function()
      vim.cmd('filetype detect')
    end)
  end
  vim.defer_fn(function()
    if not started then
      pcall(vim.api.nvim_del_autocmd, attached)
      vim.notify(
        "Couldn't watch " .. vim.fs.basename(item.path) .. ': no language server started for it',
        vim.log.levels.WARN
      )
    end
  end, 20000)
end

function M.close()
  if visible() then
    pcall(vim.api.nvim_win_close, win, false)
  end
  win = nil
end

local function create_buf()
  if buf and vim.api.nvim_buf_is_valid(buf) then
    return
  end
  buf = vim.api.nvim_create_buf(false, true)
  pcall(vim.api.nvim_buf_set_name, buf, 'Test list')
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = 'testlist'
  local function map(lhs, fn, desc, mode)
    vim.keymap.set(mode or 'n', lhs, fn, { buffer = buf, nowait = true, desc = desc })
  end
  map('<Space>', check, 'Check or uncheck')
  map('<Space>', check_selection, 'Check or uncheck the selected lines', 'x')
  map('<CR>', enter, 'Open or close the file or area / go to the test')
  map('r', run_checked, 'Run the checked tests')
  map('a', run_area, 'Run every test in this area')
  map('i', function()
    local line = current()
    if line and line.item then
      go_to(line.item)
    end
  end, 'Go to the test')
  map('o', output, "Show the test's output")
  map('w', watch, 'Watch or stop watching')
  map('/', filter, 'Filter the list as you type')
  map('<Esc>', function()
    local s = state()
    if s.filter then
      s.filter = nil
      M.draw()
    end
  end, 'Remove the filter')
  map('c', function()
    state().checked = {}
    M.draw()
  end, 'Uncheck everything')
  map('?', function()
    local s = state()
    s.help = not s.help
    M.draw()
  end, 'Show or hide the keys')
  map('q', M.close, 'Close the list')
  vim.api.nvim_create_autocmd('BufEnter', { group = group, buffer = buf, callback = M.draw })
end

function M.open()
  origin = vim.api.nvim_get_current_win()
  create_buf()
  local width = math.max(50, math.min(80, math.floor(vim.o.columns * 0.35)))
  win = vim.api.nvim_open_win(assert(buf), true, { split = 'right', win = -1 })
  vim.api.nvim_win_set_width(win, width)
  local wo = vim.wo[win][0]
  wo.number = false
  wo.relativenumber = false
  wo.signcolumn = 'no'
  wo.foldcolumn = '0'
  wo.statuscolumn = ''
  wo.foldenable = false
  wo.wrap = false
  wo.list = false
  wo.spell = false
  wo.colorcolumn = ''
  wo.cursorline = true
  wo.winfixwidth = true
  wo.winfixbuf = true
  M.refresh()
end

---,mt
function M.toggle()
  if visible() then
    M.close()
  else
    M.open()
  end
end

---neotest consumer (plugins/test.lua): the list follows discovery, runs and results
---@param neotest_client neotest.Client
function M.neotest(neotest_client)
  client = neotest_client
  local function changed()
    vim.schedule(M.refresh_soon)
  end
  client.listeners.discover_positions = changed
  client.listeners.run = changed
  client.listeners.results = changed
  return {}
end

vim.api.nvim_create_autocmd('WinClosed', {
  group = group,
  callback = function(ev)
    if tonumber(ev.match) == win then
      win = nil
    end
  end,
})
vim.api.nvim_create_autocmd({ 'VimResized', 'WinResized' }, {
  group = group,
  callback = function()
    if visible() then
      M.draw()
    end
  end,
})
vim.api.nvim_create_autocmd('DirChanged', {
  group = group,
  callback = function()
    if visible() then
      M.refresh()
    end
  end,
})
-- a saved spec or Playwright config can add, rename or remove tests
vim.api.nvim_create_autocmd('BufWritePost', {
  group = group,
  callback = function(ev)
    if not visible() then
      return
    end
    local path = vim.api.nvim_buf_get_name(ev.buf)
    for root in pairs(pw) do
      if
        vim.startswith(path, root .. '/')
        and (playwright.is_spec_file(path) or vim.fs.basename(path):match('^playwright%.config%.'))
      then
        read_playwright(root)
      end
    end
  end,
})

return M
