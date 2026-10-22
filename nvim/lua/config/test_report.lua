-- Vitest and Jest runs say how they're going: while they run, the status line
-- shows "Tests: <file>", and when they finish that turns into the result, such as
-- "✓ 12 tests passed in UserCard.test.tsx (1.2s)", kept in :messages.
-- (Playwright prints its own, in its terminal.)
local M = {}

---@class TestRun
---@field adapter string
---@field root string position id
---@field tree neotest.Tree?
---@field what string file or folder name
---@field started integer
---@field id? integer progress message
---@field stopping? boolean

local runs = {} ---@type table<string, TestRun>

---@param run TestRun
---@param text string
---@param hl? string
---@param status 'running'|'success'|'failed'|'cancel'
local function echo(run, text, hl, status)
  vim.schedule(function()
    run.id = vim.api.nvim_echo({ { text, hl } }, status ~= 'running', {
      id = run.id,
      kind = 'progress',
      title = 'Tests',
      source = 'neotest',
      status = status,
    })
  end)
end

local function plural(n, word)
  return ('%d %s%s'):format(n, word, n == 1 and '' or 's')
end

---@param run TestRun
---@param results table<string, neotest.Result>
local function finish(run, results)
  local passed, failed, skipped = 0, 0, 0
  local function add(result)
    if not result then
      return
    elseif result.status == 'passed' then
      passed = passed + 1
    elseif result.status == 'failed' then
      failed = failed + 1
    else
      skipped = skipped + 1
    end
  end
  for _, node in run.tree:iter_nodes() do
    local pos = node:data()
    if pos.type == 'test' then
      add(results[pos.id])
    elseif pos.type == 'file' and #node:children() == 0 then
      -- neotest couldn't read the tests in this file, but Jest or Vitest still
      -- ran them: count what it reported for the file
      local prefix = pos.id .. '::'
      for id, result in pairs(results) do
        if vim.startswith(id, prefix) then
          add(result)
        end
      end
    end
  end
  local after = (skipped > 0 and (', %d skipped'):format(skipped) or '')
    .. (' (%.1fs)'):format((vim.uv.hrtime() - run.started) / 1e9)
  if run.stopping then
    echo(run, ('■ Stopped: %s'):format(run.what), nil, 'cancel')
  elseif failed > 0 then
    echo(
      run,
      ('✗ %d of %s failed in %s%s'):format(failed, plural(passed + failed, 'test'), run.what, after),
      'DiagnosticError',
      'failed'
    )
  elseif passed > 0 then
    echo(run, ('✓ %s passed in %s%s'):format(plural(passed, 'test'), run.what, after), 'DiagnosticOk', 'success')
  else
    echo(run, ('No tests ran in %s%s'):format(run.what, after), nil, 'success')
  end
end

---@param run TestRun
---@param results table<string, neotest.Result>
local function covers(run, results)
  if results[run.root] then
    return true
  end
  for _, pos in run.tree:iter() do
    if results[pos.id] then
      return true
    end
  end
  return false
end

---Stop every test run in progress, wherever the cursor is. neotest's own stop
---only finds a run from the test under the cursor
---@return integer stopped how many runs
function M.stop()
  local nt = require('neotest')
  local count = 0
  for _, run in pairs(runs) do
    run.stopping = true
    nt.run.stop({ run.root, adapter = run.adapter })
    count = count + 1
  end
  return count
end

---neotest consumer: plugins/test.lua registers it
---@param client neotest.Client
function M.neotest(client)
  client.listeners.run = function(adapter_id, root_id)
    local tree = client:get_position(root_id, { adapter = adapter_id })
    if not tree then
      return
    end
    local key = adapter_id .. '\0' .. root_id
    local run = {
      adapter = adapter_id,
      root = root_id,
      tree = tree,
      what = vim.fs.basename(tree:data().path),
      started = vim.uv.hrtime(),
      -- running the same tests again, such as on save while watching, reuses the message
      id = runs[key] and runs[key].id,
    }
    runs[key] = run
    echo(run, run.what, nil, 'running')
  end
  client.listeners.results = function(adapter_id, results, partial)
    if partial then
      return
    end
    for key, run in pairs(runs) do
      if run.adapter == adapter_id and covers(run, results) then
        runs[key] = nil
        finish(run, results)
      end
    end
  end
  return {}
end

return M
