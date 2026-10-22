local pack = require('config.pack')
local playwright = require('config.playwright')

pack.defer({
  'https://github.com/nvim-neotest/nvim-nio',
  'https://github.com/nvim-neotest/neotest',
  'https://github.com/marilari88/neotest-vitest',
  'https://github.com/nvim-neotest/neotest-jest',
})

-- Build output and caches never contain tests worth discovering
local skip_dirs = {}
for _, name in ipairs({
  'node_modules',
  '.git',
  'dist',
  'build',
  'out',
  'coverage',
  '.next',
  '.turbo',
  '.vite',
  '.vercel',
  'storybook-static',
  'playwright-report',
  'test-results',
}) do
  skip_dirs[name] = true
end

local jest_configs = {
  'jest.config.ts',
  'jest.config.js',
  'jest.config.mts',
  'jest.config.mjs',
  'jest.config.cts',
  'jest.config.cjs',
  'jest.config.json',
}

-- neotest reads the tests out of each file in a background Neovim started without
-- this config, which doesn't know that .tsx and .jsx files use the tsx and
-- javascript parsers, and so finds no tests in them. Tell it as soon as it starts;
-- drop this once nvim-neotest/neotest#631 is fixed
local function fix_tsx_discovery()
  local function warn(why)
    vim.schedule(function()
      vim.notify(
        ('Tests in .tsx and .jsx files may not be found: %s. See fix_tsx_discovery in plugins/test.lua'):format(why),
        vim.log.levels.WARN
      )
    end)
  end
  local ok, subprocess = pcall(require, 'neotest.lib.subprocess')
  for _, name in ipairs({ 'init', 'call', 'enabled' }) do
    if not ok or not vim.is_callable(subprocess[name]) then
      warn('neotest has changed')
      return
    end
  end
  local init = subprocess.init
  subprocess.init = function(...)
    init(...)
    if not subprocess.enabled() then
      return
    end
    for _, ft in ipairs({ 'typescriptreact', 'javascriptreact' }) do
      local lang = vim.treesitter.language.get_lang(ft)
      if lang and lang ~= ft then
        local done, err = pcall(subprocess.call, 'vim.treesitter.language.register', { lang, ft })
        if not done then
          warn(tostring(err):match('[^\n]*'))
          return
        end
      end
    end
  end
end

local setup = pack.once(function()
  pack.load({ 'nvim-nio', 'neotest', 'neotest-vitest', 'neotest-jest' })
  fix_tsx_discovery()
  local vitest = require('neotest-vitest')
  -- captured before setup: passing is_test_file replaces the adapter's own check
  local is_vitest_file = vitest.is_test_file
  local is_jest_file = require('neotest-jest.jest-util').defaultIsTestFile
  ---@diagnostic disable-next-line: missing-fields
  require('neotest').setup({
    adapters = {
      vitest({
        filter_dir = function(name)
          return not skip_dirs[name]
        end,
        -- Playwright specs share the *.spec.ts naming; they run through Playwright
        is_test_file = function(path)
          return is_vitest_file(path) and not playwright.is_spec_file(path)
        end,
      }),
      require('neotest-jest')({
        isTestFile = function(path)
          return is_jest_file(path) and not playwright.is_spec_file(path)
        end,
        -- The adapter's own lookup calls vim.fn.glob in a fast event and fails;
        -- drop this once nvim-neotest/neotest-jest#192 is released
        jestConfigFile = function(path)
          return vim.fs.find(jest_configs, { path = vim.fs.dirname(path), upward = true, limit = 1 })[1]
        end,
        -- the package the test belongs to, wherever Neovim was started
        cwd = function(path)
          local pkg = vim.fs.find('package.json', { path = vim.fs.dirname(path), upward = true, limit = 1 })[1]
          return pkg and vim.fs.dirname(pkg)
        end,
      }),
    },
    consumers = {
      -- the iTerm2 tab's status dot and a notification after each run (config/iterm.lua)
      iterm = require('config.iterm').neotest,
      -- "Tests: <file>" in the status line while they run, then the result (config/test_report.lua)
      report = require('config.test_report').neotest,
    },
  })
end)

local last = 'neotest'

---neotest discovers in the background after :cd and for new files, so a run
---right away would say "No tests found": give discovery a moment first
---@param fn fun()
local function when_discovered(fn)
  local nt = require('neotest')
  local buf = vim.api.nvim_get_current_buf()
  local function known()
    local ids = nt.state.adapter_ids()
    -- before the first run nothing is started yet, and starting waits for discovery
    if #ids == 0 then
      return true
    end
    for _, id in ipairs(ids) do
      if nt.state.positions(id, { buffer = buf }) then
        return true
      end
    end
  end
  local deadline = vim.uv.now() + 3000
  local function try()
    if known() or vim.uv.now() > deadline then
      fn()
    else
      vim.defer_fn(try, 100)
    end
  end
  try()
end

---Playwright specs go to Playwright, everything else to neotest
---@param pw fun()
---@param nt fun(neotest: table)
local function either(pw, nt)
  return function()
    if playwright.is_spec() then
      last = 'playwright'
      pw()
    else
      setup()
      last = 'neotest'
      when_discovered(function()
        nt(require('neotest'))
      end)
    end
  end
end

local function neotest(fn)
  return function()
    setup()
    fn(require('neotest'))
  end
end

local file = function()
  return vim.api.nvim_buf_get_name(0)
end

for _, map in ipairs({
  {
    '<leader>mr',
    either(playwright.run_nearest, function(nt)
      nt.run.run()
    end),
    'Run nearest test',
  },
  {
    '<leader>ma',
    either(playwright.run_file, function(nt)
      nt.run.run(file())
    end),
    'Run tests in file',
  },
  {
    '<leader>md',
    either(playwright.debug_nearest, function(nt)
      require('plugins.debug').setup()
      nt.run.run({ strategy = 'dap' })
    end),
    'Debug nearest test',
  },
  {
    '<leader>ml',
    function()
      if last == 'playwright' then
        playwright.run_last()
      else
        setup()
        require('neotest').run.run_last()
      end
    end,
    'Re-run last tests',
  },
  {
    '<leader>mw',
    neotest(function(nt)
      nt.watch.toggle(file())
    end),
    'Watch file (re-run on save)',
  },
  {
    '<leader>mx',
    neotest(function()
      if require('config.test_report').stop() == 0 then
        vim.notify('No tests are running')
      end
    end),
    'Stop tests',
  },
  {
    '<leader>mo',
    neotest(function(nt)
      nt.output.open({ enter = true })
    end),
    'Output of nearest test',
  },
  {
    '<leader>mO',
    neotest(function(nt)
      nt.output_panel.toggle()
    end),
    'Output panel',
  },
  {
    '<leader>ms',
    neotest(function(nt)
      nt.summary.toggle()
    end),
    'Test summary',
  },
  { '<leader>mu', playwright.ui, 'Playwright UI mode' },
  { '<leader>mi', playwright.inspector, 'Playwright inspector (nearest test)' },
}) do
  vim.keymap.set('n', map[1], map[2], { desc = map[3] })
end

return { setup = setup }
