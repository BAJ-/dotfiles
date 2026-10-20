-- Local-first AI: a local Ollama model when it's running and the model is
-- pulled, GitHub Copilot otherwise. Nothing here installs anything; missing
-- pieces are reported by :AIStatus with the command that fixes them.
local M = {}

M.chat_model = vim.env.AI_LOCAL_MODEL or 'qwen3-coder:30b'
M.fim_model = vim.env.AI_LOCAL_FIM_MODEL or 'qwen2.5-coder:7b'

---@return string
function M.ollama_url()
  local host = vim.env.OLLAMA_HOST or 'http://localhost:11434'
  return host:match('^https?://') and host or ('http://' .. host)
end

local function tagged(model)
  return model:find(':') and model or (model .. ':latest')
end

---Models Ollama has pulled, or nil when it isn't reachable
---@return string[]?
function M.ollama_models()
  if vim.fn.executable('curl') == 0 then
    return nil
  end
  local out = vim.system({ 'curl', '-fsS', '--max-time', '1', M.ollama_url() .. '/api/tags' }, { text = true }):wait()
  if out.code ~= 0 then
    return nil
  end
  local ok, data = pcall(vim.json.decode, out.stdout)
  if not ok or type(data) ~= 'table' then
    return nil
  end
  return vim.tbl_map(function(m)
    return m.name
  end, data.models or {})
end

---@param model string
---@return boolean available, string reason
function M.local_model(model)
  local models = M.ollama_models()
  if not models then
    return false, ("Ollama isn't running at %s (brew install ollama, then: ollama serve)"):format(M.ollama_url())
  end
  if not vim.list_contains(models, tagged(model)) then
    return false, ("%s isn't pulled (ollama pull %s)"):format(model, model)
  end
  return true, ('local model %s'):format(model)
end

---Chat backend: local model, else Copilot CLI (ACP), else Copilot chat
---@return { adapter: string, model?: string }, string reason
function M.chat_backend()
  local ok, why = M.local_model(M.chat_model)
  if ok then
    return { adapter = 'ollama', model = M.chat_model }, why
  end
  if vim.fn.executable('copilot') == 1 then
    return { adapter = 'copilot_acp' }, 'Copilot CLI, because ' .. why
  end
  return { adapter = 'copilot' }, 'Copilot chat, because ' .. why .. " and Copilot CLI isn't installed"
end

-- AI suggestions are off until you turn them on: ghost text with <leader>al,
-- next edit suggestions with <leader>an. Copilot's language server only runs
-- while one of them needs it.
M.ghost_text = false

-- Ghost text comes from one provider at a time: 'copilot' or 'local' (minuet)
M.inline_provider = 'copilot'

local inline_clients = { copilot = 'copilot', ['local'] = 'minuet' }

---@return string
function M.ghost_text_source()
  return M.inline_provider == 'local' and ('local model ' .. M.fim_model) or 'Copilot'
end

---Let a client show ghost text only when it's on and from this client's provider
---@param client vim.lsp.Client
function M.apply_inline(client)
  for provider, name in pairs(inline_clients) do
    if client.name == name then
      vim.lsp.inline_completion.enable(M.ghost_text and provider == M.inline_provider, { client_id = client.id })
    end
  end
end

local function nes_on()
  local ok, nes = pcall(require, 'sidekick.nes')
  return ok and nes.enabled
end

---Start Copilot's language server while ghost text or next edit suggestions
---need it, and stop it when neither does
function M.sync_copilot()
  local wanted = (M.ghost_text and M.inline_provider == 'copilot') or nes_on()
  if wanted ~= vim.lsp.is_enabled('copilot') then
    vim.lsp.enable('copilot', wanted)
  end
end

---@param provider 'copilot'|'local'
function M.set_inline_provider(provider)
  M.inline_provider = provider
  for _, client in ipairs(vim.lsp.get_clients()) do
    M.apply_inline(client)
  end
  M.sync_copilot()
end

---@param on boolean
function M.set_ghost_text(on)
  M.ghost_text = on
  M.set_inline_provider(M.inline_provider)
end

function M.status()
  local lines = {}
  local function add(fmt, ...)
    lines[#lines + 1] = fmt:format(...)
  end

  local copilot = vim.lsp.get_clients({ name = 'copilot' })[1]
  if copilot then
    add('Copilot language server: running')
  elseif vim.fn.executable('copilot-language-server') == 1 then
    add('Copilot language server: installed, starts when ghost text or next edit suggestions need it')
  else
    add('Copilot language server: not installed yet (Mason installs it in the background)')
  end
  add(
    'Ghost text (<leader>al): %s, from %s (<leader>aL switches)',
    M.ghost_text and 'on' or 'off',
    M.ghost_text_source()
  )
  add('Next Edit Suggestions (<leader>an): %s', nes_on() and 'on' or 'off')

  local models = M.ollama_models()
  add(
    'Ollama (%s): %s',
    M.ollama_url(),
    models and ('running, models: ' .. (#models > 0 and table.concat(models, ', ') or 'none')) or 'not reachable'
  )
  local chat_ok, chat_why = M.local_model(M.chat_model)
  add('  chat/agent model AI_LOCAL_MODEL=%s: %s', M.chat_model, chat_ok and 'available' or chat_why)
  local fim_ok, fim_why = M.local_model(M.fim_model)
  add('  ghost-text model AI_LOCAL_FIM_MODEL=%s: %s', M.fim_model, fim_ok and 'available' or fim_why)

  local _, backend_why = M.chat_backend()
  add('Chat (<leader>ac) uses: %s', backend_why)
  if vim.fn.executable('copilot') == 0 then
    add("Agent CLI (<leader>aa): Copilot CLI isn't installed (brew install --cask copilot-cli)")
  else
    add('Agent CLI (<leader>aa): copilot-auto -> %s', chat_ok and ('local model ' .. M.chat_model) or "GitHub's models")
  end
  return lines
end

return M
