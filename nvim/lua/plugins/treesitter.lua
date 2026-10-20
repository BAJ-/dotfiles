local pack = require('config.pack')

pack.add({
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter', version = 'main' },
  'https://github.com/windwp/nvim-ts-autotag',
  'https://github.com/nvim-treesitter/nvim-treesitter-context',
})

local parsers = {
  'bash',
  'css',
  'diff',
  'dockerfile',
  'git_config',
  'git_rebase',
  'gitattributes',
  'gitcommit',
  'gitignore',
  'graphql',
  'html',
  'javascript',
  'jsdoc',
  'json',
  'json5',
  'lua',
  'luadoc',
  'markdown',
  'markdown_inline',
  'query',
  'regex',
  'scss',
  'styled', -- CSS inside styled-components / emotion template literals
  'toml',
  'tsx',
  'typescript',
  'vim',
  'vimdoc',
  'yaml',
}

local function attach(buf)
  local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
  if not lang or not pcall(vim.treesitter.start, buf, lang) then
    return
  end
  if #vim.treesitter.query.get_files(lang, 'indents') > 0 then
    vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end
  if vim.api.nvim_get_current_buf() == buf then
    vim.wo[0][0].foldmethod = 'expr'
    vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
  end
end

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('user.treesitter', { clear = true }),
  callback = function(ev)
    attach(ev.buf)
  end,
})

-- Interactive sessions build missing parsers in the background; setup.sh
-- installs them synchronously instead (see `parsers` below)
if #vim.api.nvim_list_uis() > 0 then
  local installed = {}
  for _, lang in ipairs(require('nvim-treesitter').get_installed()) do
    installed[lang] = true
  end
  local missing = vim.tbl_filter(function(lang)
    return not installed[lang]
  end, parsers)

  if #missing > 0 then
    if vim.fn.executable('tree-sitter') == 0 then
      vim.notify('Treesitter parsers need tree-sitter-cli: brew install tree-sitter-cli', vim.log.levels.WARN)
    else
      require('nvim-treesitter').install(missing):await(vim.schedule_wrap(function()
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_loaded(buf) then
            attach(buf)
          end
        end
      end))
    end
  end
end

require('nvim-ts-autotag').setup()

-- Sticky context: the enclosing component, function or describe/it stays
-- visible at the top while scrolling (one line each, three at most)
pack.later('plugins.treesitter', function()
  require('treesitter-context').setup({ max_lines = 3, multiline_threshold = 1 })
end)
vim.keymap.set('n', '<leader>cx', function()
  require('treesitter-context').toggle()
end, { desc = 'Sticky context on/off' })

return { parsers = parsers }
