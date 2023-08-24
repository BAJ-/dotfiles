vim.cmd([[
set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath
source ~/.vimrc
]])
vim.opt.termguicolors = true

-- Run setup for Hop
require'hop'.setup()


require'nvim-web-devicons'.setup {
  default = true;
}

require'nvim-tree'.setup {
}

require'nvim-treesitter.configs'.setup {
  -- One of "all", "maintained" (parsers with maintainers), or a list of languages
  ensure_installed = {'bash', 'javascript', 'lua', 'go', 'gomod', 'typescript', 'tsx', 'html', 'css', 'scss', 'toml', 'yaml', 'json', 'regex', 'make', 'dot', 'dockerfile', 'ruby', 'python'},

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
}

require('telescope').setup{  defaults = { file_ignore_patterns = { "node_modules" }} }

-- DEBUGGING ---
-- Run setup for Mason
require("mason").setup()
-- Setup Dap
require('dap.setup').setup()

-- Get iterm profile
local iterm_profile = os.getenv('ITERM_PROFILE')
if(iterm_profile == 'tokyonight-storm')
then
  colorSchemeName = 'tokyonight-storm'
else
  colorSchemeName = 'zengarden'
end

-- Set colorscheme
vim.cmd.colorscheme(colorSchemeName)

-- Statusline
local function git_branch()
    local branch = vim.fn.system("git rev-parse --abbrev-ref HEAD 2>/dev/null | tr -d '\n'")
    if string.len(branch) > 0 then
        return branch
    else
        return ":"
    end
end

local function statusline()
    local set_color_1 = "%#Search#"
    local branch = git_branch()
    local set_color_2 = "%#MoreMsg#"
    local file_name = " %f"
    local modified = "%m"
    local align_right = "%="
    local fileencoding = " %{&fileencoding?&fileencoding:&encoding}"
    local fileformat = " [%{&fileformat}]"
    local filetype = " %y"
    local percentage = " %p%%"
    local linecol = " %l:%c"

    return string.format(
        "%s %s %s%s%s%s%s%s%s%s%s",
        set_color_1,
        branch,
        set_color_2,
        file_name,
        modified,
        align_right,
        filetype,
        fileencoding,
        fileformat,
        percentage,
        linecol
    )
end

vim.opt.statusline = statusline()
