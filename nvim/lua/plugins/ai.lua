local pack = require('config.pack')
local ai = require('config.ai')

pack.add({ 'https://github.com/folke/sidekick.nvim' })
pack.defer({
  'https://github.com/nvim-lua/plenary.nvim',
  -- major versions change its config; move to the next one deliberately
  { src = 'https://github.com/olimorris/codecompanion.nvim', version = vim.version.range('20.*') },
  'https://github.com/milanglacier/minuet-ai.nvim',
})

-- Copilot ghost text through Neovim's own LSP client (no copilot.vim). AI
-- suggestions are off until you turn them on (<leader>al, <leader>an), and
-- Copilot's server only runs while one of them needs it (ai.sync_copilot).
-- Sign in once: <leader>al, then :LspCopilotSignIn.
-- This only lets buffers show ghost text; ai.apply_inline decides per client
-- whether that client may (on, and from the chosen provider)
vim.lsp.inline_completion.enable(true)

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('user.ai', { clear = true }),
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client then
      ai.apply_inline(client)
    end
  end,
})

-- Accept ghost text with <Tab> when the completion menu isn't open (see
-- plugins/completion.lua); cycle suggestions like copilot.vim did
vim.keymap.set('i', '<M-]>', function()
  vim.lsp.inline_completion.select({ count = 1 })
end, { desc = 'Next ghost text suggestion' })
vim.keymap.set('i', '<M-[>', function()
  vim.lsp.inline_completion.select({ count = -1 })
end, { desc = 'Previous ghost text suggestion' })

-- sidekick: Copilot Next Edit Suggestions + AI CLIs in a terminal ----------

pack.later('plugins.ai', function()
  require('sidekick').setup({
    -- off until <leader>an
    nes = { enabled = false },
    cli = {
      picker = 'fzf-lua',
      tools = {
        -- local model when available, GitHub's models otherwise (bin/copilot-auto)
        copilot = { cmd = { 'copilot-auto', '--banner' } },
        copilot_github = { cmd = { 'copilot', '--banner' } },
      },
    },
  })
end)

-- Normal-mode <Tab> jumps to / applies the next edit suggestion, else acts as usual
vim.keymap.set('n', '<Tab>', function()
  if not require('sidekick').nes_jump_or_apply() then
    return '<Tab>'
  end
end, { expr = true, desc = 'Next edit suggestion' })

local function cli(fn, opts)
  return function()
    require('sidekick.cli')[fn](opts)
  end
end
local map = vim.keymap.set
map('n', '<leader>aa', cli('toggle', { name = 'copilot', focus = true }), { desc = 'Agent CLI (local first)' })
map(
  'n',
  '<leader>ag',
  cli('toggle', { name = 'copilot_github', focus = true }),
  { desc = 'Agent CLI on GitHub models' }
)
map('n', '<leader>as', cli('select'), { desc = 'Choose agent CLI' })
map({ 'n', 'x' }, '<leader>at', cli('send', { msg = '{this}' }), { desc = 'Send this to agent' })
map('n', '<leader>af', cli('send', { msg = '{file}' }), { desc = 'Send file to agent' })
map('x', '<leader>av', cli('send', { msg = '{selection}' }), { desc = 'Send selection to agent' })
map({ 'n', 'x' }, '<leader>ap', cli('prompt'), { desc = 'Agent prompts' })
map('n', '<leader>an', function()
  local nes = require('sidekick.nes')
  nes.enable(not nes.enabled)
  ai.sync_copilot()
  vim.notify('Next Edit Suggestions ' .. (nes.enabled and 'on' or 'off'))
end, { desc = 'Next edit suggestions on/off' })

-- CodeCompanion chat: local model first, then Copilot CLI, then Copilot ----

local setup_chat = pack.once(function()
  pack.load({ 'plenary.nvim', 'codecompanion.nvim' })
  local backend = ai.chat_backend()
  require('codecompanion').setup({
    interactions = {
      chat = { adapter = backend.adapter },
      inline = { adapter = backend.adapter == 'copilot_acp' and 'copilot' or backend.adapter },
    },
    adapters = {
      http = {
        ollama = function()
          return require('codecompanion.adapters').extend('ollama', {
            env = { url = ai.ollama_url() },
            schema = { model = { default = ai.chat_model } },
          })
        end,
      },
    },
  })
end)

local function open_chat()
  setup_chat()
  local backend, why = ai.chat_backend()
  vim.notify('Chat: ' .. why)
  require('codecompanion').chat({ params = backend })
end

map('n', '<leader>ac', open_chat, { desc = 'AI chat (local first)' })
map('x', '<leader>ac', function()
  setup_chat()
  -- '< and '> only point at this selection once visual mode has ended
  vim.cmd('normal! ' .. vim.keycode('<Esc>'))
  vim.cmd("'<,'>CodeCompanionChat Add")
end, { desc = 'Add selection to AI chat' })
pack.on_cmds({ 'CodeCompanion', 'CodeCompanionChat', 'CodeCompanionActions', 'CodeCompanionCmd' }, setup_chat)

-- Local ghost text (minuet + Ollama), chosen with <leader>aL ----------------

local setup_minuet = pack.once(function()
  pack.load({ 'plenary.nvim', 'minuet-ai.nvim' })
  local fts = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact', 'css', 'scss', 'html', 'json', 'lua' }
  require('minuet').setup({
    provider = 'openai_fim_compatible',
    n_completions = 1,
    context_window = 2048,
    provider_options = {
      openai_fim_compatible = {
        api_key = 'TERM', -- Ollama needs no key; minuet wants the name of a set env var
        name = 'Ollama',
        end_point = ai.ollama_url() .. '/v1/completions',
        model = ai.fim_model,
        optional = { max_tokens = 128, top_p = 0.9 },
      },
    },
    lsp = {
      enabled_ft = fts,
      completion = { enable = false },
      inline_completion = { enable = true, enabled_auto_trigger_ft = fts },
    },
  })
  -- Buffers that were already open
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.list_contains(fts, vim.bo[buf].filetype) then
      vim.api.nvim_buf_call(buf, function()
        vim.cmd('silent! Minuet lsp attach')
      end)
    end
  end
end)

map('n', '<leader>al', function()
  if ai.ghost_text then
    ai.set_ghost_text(false)
    vim.notify('Ghost text off')
    return
  end
  if ai.inline_provider == 'local' then
    local ok, why = ai.local_model(ai.fim_model)
    if ok then
      setup_minuet()
    else
      ai.inline_provider = 'copilot'
      vim.notify('Local model unavailable, using Copilot: ' .. why, vim.log.levels.WARN)
    end
  end
  ai.set_ghost_text(true)
  vim.notify('Ghost text on: ' .. ai.ghost_text_source())
end, { desc = 'Ghost text on/off' })

map('n', '<leader>aL', function()
  if ai.inline_provider == 'local' then
    ai.set_inline_provider('copilot')
  else
    local ok, why = ai.local_model(ai.fim_model)
    if not ok then
      vim.notify('Ghost text stays on Copilot: ' .. why, vim.log.levels.WARN)
      return
    end
    if ai.ghost_text then
      setup_minuet()
    end
    ai.set_inline_provider('local')
  end
  vim.notify('Ghost text from ' .. ai.ghost_text_source() .. (ai.ghost_text and '' or ' (off; ,al turns it on)'))
end, { desc = 'Ghost text: Copilot or local model' })

vim.api.nvim_create_user_command('AIStatus', function()
  vim.notify(table.concat(ai.status(), '\n'))
end, { desc = 'Show which AI backends are active and why' })
