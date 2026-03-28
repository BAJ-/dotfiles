vim.cmd([[
set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath
source ~/.vimrc
]])
vim.opt.termguicolors = true

-- Ensure nvm-managed Node.js is in PATH for ALE/linters
local nvm_dir = os.getenv("NVM_DIR")
if nvm_dir then
  local default_node = nvm_dir .. "/versions/node"
  local handle = io.popen("ls -1 " .. default_node .. " 2>/dev/null | sort -V | tail -1")
  if handle then
    local latest = handle:read("*l")
    handle:close()
    if latest then
      vim.env.PATH = default_node .. "/" .. latest .. "/bin:" .. vim.env.PATH
    end
  end
end

-- Run setup for Hop
require'hop'.setup()


require'nvim-web-devicons'.setup {
  default = true;
}

require'nvim-tree'.setup {
  view = {
    adaptive_size = true
  },
  sync_root_with_cwd = true,
  renderer = {
    add_trailing = true,
    group_empty = true,
    highlight_git = true,
    highlight_opened_files = "all",
    root_folder_label = ":~",
    indent_markers = {
      enable = true,
    },
    special_files = { "README.md", "Makefile", "MAKEFILE" },
    icons = {
      padding = " ",
      show = {
        git = true,
        folder = true,
        file = true,
        folder_arrow = true,
      },
      glyphs = {
        git = {
          unstaged = "✗",
          staged = "✓",
          unmerged = "",
          renamed = "➜",
          untracked = "★",
          deleted = "",
          ignored = "◌",
        },
      },
    },
  },
  actions = {
    open_file = {
      resize_window = true,
    },
  },
}

require'nvim-treesitter.configs'.setup {
  -- One of "all", "maintained" (parsers with maintainers), or a list of languages
  ensure_installed = {'bash', 'javascript', 'lua', 'go', 'gomod', 'typescript', 'tsx', 'html', 'css', 'scss', 'toml', 'yaml', 'json', 'regex', 'make', 'dot', 'dockerfile', 'ruby', 'python', 'graphql'},

  -- Install languages synchronously (only applied to `ensure_installed`)
  sync_install = false,

  -- List of parsers to ignore installing
  -- ignore_install = { "javascript" },

  highlight = {
    -- `false` will disable the whole extension
    enable = true,

    -- NOTE: these are the names of the parsers and not the filetype. (for example if you want to
    -- disable highlighting for the `tex` filetype, you need to include `latex` in this list as this is
    -- the name of the parser)
    -- list of language that will be disabled
    -- disable = { "c", "rust" },

    -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
    -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
    -- Using this option may slow down your editor, and you may see some duplicate highlights.
    -- Instead of true it can also be a list of languages
    additional_vim_regex_highlighting = false,
  },
  indent = {
    enable = true,
  },
}

require('nvim-ts-autotag').setup()

local telescope = require('telescope')
telescope.setup{  defaults = { file_ignore_patterns = { "node_modules", "vendor" }} }
-- Load live grep args extension
telescope.load_extension("live_grep_args")
vim.keymap.set('n', '<leader>fg', telescope.extensions.live_grep_args.live_grep_args, { noremap = true })

-- Which-key setup
require("which-key").setup()

-- Open git changed/new files in smart split layout
local function open_in_layout(files)
  if #files == 0 then return end

  -- Focus a non-NvimTree window, or create one
  local tree_open = false
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "NvimTree" then
      tree_open = true
    else
      vim.api.nvim_set_current_win(win)
    end
  end

  -- Close other file windows (keep NvimTree)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype ~= "NvimTree" and win ~= vim.api.nvim_get_current_win() then
      pcall(vim.api.nvim_win_close, win, false)
    end
  end

  vim.cmd("edit " .. vim.fn.fnameescape(files[1]))

  if #files == 2 then
    vim.cmd("vsplit " .. vim.fn.fnameescape(files[2]))
  elseif #files == 3 then
    vim.cmd("split " .. vim.fn.fnameescape(files[2]))
    vim.cmd("vsplit " .. vim.fn.fnameescape(files[3]))
  elseif #files >= 4 then
    local top = math.ceil(#files / 2)
    for i = 2, top do
      vim.cmd("vsplit " .. vim.fn.fnameescape(files[i]))
    end
    vim.cmd("wincmd t")
    vim.cmd("split " .. vim.fn.fnameescape(files[top + 1]))
    for i = top + 2, #files do
      vim.cmd("vsplit " .. vim.fn.fnameescape(files[i]))
    end
  end
  vim.cmd("wincmd t")
end

local function pick_changed_files()
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  local output = vim.fn.systemlist("git ls-files --modified --others --exclude-standard 2>/dev/null")
  local diff = vim.fn.systemlist("git diff --name-only HEAD 2>/dev/null")
  local seen = {}
  local files = {}
  for _, list in ipairs({output, diff}) do
    for _, f in ipairs(list) do
      if f ~= "" and not seen[f] then
        seen[f] = true
        table.insert(files, f)
      end
    end
  end

  if #files == 0 then
    print("No changed or new files found")
    return
  end

  pickers.new({}, {
    prompt_title = "Changed/New Files (Tab to select, Enter to open)",
    finder = finders.new_table({ results = files }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        local picker = action_state.get_current_picker(prompt_bufnr)
        local selections = picker:get_multi_selection()
        actions.close(prompt_bufnr)

        local selected = {}
        if #selections > 0 then
          for _, entry in ipairs(selections) do
            table.insert(selected, entry[1])
          end
        else
          local entry = action_state.get_selected_entry()
          if entry then table.insert(selected, entry[1]) end
        end
        open_in_layout(selected)
      end)
      return true
    end,
  }):find()
end

vim.keymap.set('n', '<leader>gf', pick_changed_files, { noremap = true, desc = "Open changed files in layout" })

-- LSP + Auto-completion setup
local lspconfig = require('lspconfig')
local cmp = require('cmp')
local luasnip = require('luasnip')

-- nvim-cmp setup
cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = false }),
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { 'i', 's' }),
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
  }, {
    { name = 'buffer' },
    { name = 'path' },
  }),
})

-- LSP capabilities for nvim-cmp
local capabilities = require('cmp_nvim_lsp').default_capabilities()

-- TypeScript/JavaScript
lspconfig.ts_ls.setup({
  capabilities = capabilities,
})

-- Go
lspconfig.gopls.setup({
  capabilities = capabilities,
})

-- Disable ALE's LSP features to avoid duplicates (ALE handles linting, LSP handles completion)
vim.g.ale_disable_lsp = 1

-- DEBUGGING ---
-- Run setup for Mason
require("mason").setup()
-- Setup Dap
require('dap.setup').setup()

--- Neotest
require("neotest").setup({
  adapters = {
    require('neotest-jest')({
      jestCommand = "npm test --",
      jestConfigFile = "jest.config.ts",
      env = { CI = true },
      cwd = function(path)
        return vim.fn.getcwd()
      end,
    }),
  },
})

-- Run nearest test
vim.api.nvim_set_keymap('n', '<leader>mr', '<cmd>lua require("neotest").run.run()<CR><cmd>lua require("neotest").summary.open()<CR>', { noremap = true, silent = true })
-- Open output
vim.api.nvim_set_keymap('n', '<leader>mo', '<cmd>lua require("neotest").output.open({ enter = true })<CR>', { noremap = true, silent = true })
-- Run all tests in file
vim.api.nvim_set_keymap('n', '<leader>ma', '<cmd>lua require("neotest").run.run(vim.fn.expand("%"))<CR><cmd>lua require("neotest").summary.open()<CR>', { noremap = true, silent = true })
-- Toggle summary
vim.api.nvim_set_keymap('n', '<leader>ms', '<cmd>lua require("neotest").summary.toggle()<CR>', { noremap = true, silent = true })

-- Get iterm profile
local iterm_profile = os.getenv('ITERM_PROFILE')
if(iterm_profile == 'tokyonight-storm')
then
  local colorSchemeName = 'tokyonight-storm'
  vim.cmd.colorscheme(colorSchemeName)
else
  vim.o.background = 'light'
  local colorSchemeName = 'kanagawa'
  require('kanagawa').setup({
    compile = false,             -- enable compiling the colorscheme
    undercurl = true,            -- enable undercurls
    commentStyle = { italic = true },
    functionStyle = {},
    keywordStyle = { italic = true},
    statementStyle = { bold = true },
    typeStyle = {},
    transparent = false,         -- do not set background color
    dimInactive = false,         -- dim inactive window `:h hl-NormalNC`
    terminalColors = true,       -- define vim.g.terminal_color_{0,17}
    colors = {                   -- add/modify theme and palette colors
        palette = {},
        theme = { wave = {}, lotus = {}, dragon = {}, all = {} },
    },
    overrides = function(colors) -- add/modify highlights
        return {}
    end,
    theme = "wave",              -- Load "wave" theme when 'background' option is not set
    background = {               -- map the value of 'background' option to a theme
        dark = "wave",           -- try "dragon" !
        light = "lotus"
    }, 
  })
  vim.cmd.colorscheme(colorSchemeName)
end

-- ALE linting status indicator
vim.g.ale_linting = false
vim.api.nvim_create_autocmd("User", {
  pattern = "ALELintPre",
  callback = function() vim.g.ale_linting = true; vim.cmd("redrawstatus") end,
})
vim.api.nvim_create_autocmd("User", {
  pattern = "ALELintPost",
  callback = function() vim.g.ale_linting = false; vim.cmd("redrawstatus") end,
})

-- Statusline
local cached_branch = ":"
local function update_git_branch()
    local branch = vim.fn.system("git rev-parse --abbrev-ref HEAD 2>/dev/null | tr -d '\n'")
    cached_branch = string.len(branch) > 0 and branch or ":"
    vim.cmd("redrawstatus")
end

vim.api.nvim_create_autocmd({"BufEnter", "FocusGained", "DirChanged"}, {
  callback = update_git_branch,
})
update_git_branch()

-- Highlight for linting indicator and mode
vim.api.nvim_set_hl(0, "StatusLineLinting", { fg = "#1a1b26", bg = "#9ece6a" })
vim.api.nvim_set_hl(0, "StatusLineMode", { fg = "#1a1b26", bg = "#7aa2f7" })

local mode_map = {
  n = "NORMAL", i = "INSERT", v = "VISUAL", V = "V-LINE",
  ["\22"] = "V-BLOCK", c = "COMMAND", R = "REPLACE", t = "TERMINAL",
  s = "SELECT", S = "S-LINE", ["\19"] = "S-BLOCK",
}

function _G.statusline()
    local set_color_1 = "%#Search#"
    local branch = cached_branch
    local set_color_2 = "%#MoreMsg#"
    local file_name = " %f"
    local modified = "%m"
    local align_right = "%="
    local mode = mode_map[vim.fn.mode()] or vim.fn.mode()
    local mode_display = "%#StatusLineMode# " .. mode .. " %#MoreMsg#"
    local lint_status = vim.g.ale_linting and "%#StatusLineLinting# [linting...] %#MoreMsg#" or ""
    local fileencoding = " %{&fileencoding?&fileencoding:&encoding}"
    local fileformat = " [%{&fileformat}]"
    local filetype = " %y"
    local percentage = " %p%%"
    local linecol = " %l:%c"

    return string.format(
        "%s %s %s%s%s%s%s%s%s%s%s%s%s",
        set_color_1,
        branch,
        set_color_2,
        file_name,
        modified,
        align_right,
        mode_display,
        lint_status,
        filetype,
        fileencoding,
        fileformat,
        percentage,
        linecol
    )
end

vim.opt.statusline = "%!v:lua.statusline()"
