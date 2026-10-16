local pack = require('config.pack')

pack.add({
  'https://github.com/folke/tokyonight.nvim',
  'https://github.com/rebelot/kanagawa.nvim',
  'https://github.com/nvim-tree/nvim-web-devicons',
})

-- Same two themes as before, chosen from the terminal's light/dark background
-- (detected by Neovim) instead of $ITERM_PROFILE, so it works in any terminal.
-- Compare families: Neovim reloads the active theme when 'background' changes
-- (tokyonight then turns itself into tokyonight-day) and kanagawa always
-- reports its name as plain "kanagawa".
local function apply_theme()
  local name = vim.g.colors_name or ''
  if vim.o.background == 'light' then
    if not name:find('^kanagawa') then
      vim.cmd.colorscheme('kanagawa-lotus')
    end
  elseif name ~= 'tokyonight-storm' then
    vim.cmd.colorscheme('tokyonight-storm')
  end
end

apply_theme()
vim.api.nvim_create_autocmd('OptionSet', {
  group = vim.api.nvim_create_augroup('user.theme', { clear = true }),
  pattern = 'background',
  callback = apply_theme,
})

require('config.statusline').setup()
