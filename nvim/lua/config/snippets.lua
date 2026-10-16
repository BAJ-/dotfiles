-- Browse the snippets available in the current buffer (including the
-- filetypes it extends) and insert one
local M = {}

function M.pick()
  local ls = require('luasnip')
  local labels, by_label = {}, {}
  for _, ft in ipairs(ls.get_snippet_filetypes()) do
    for _, snip in ipairs(ls.get_snippets(ft) or {}) do
      local label = ('%-6s %s  [%s]'):format(snip.trigger, snip.name or snip.trigger, ft)
      if not by_label[label] then
        by_label[label] = snip
        labels[#labels + 1] = label
      end
    end
  end
  if #labels == 0 then
    vim.notify('No snippets for ' .. vim.bo.filetype)
    return
  end

  require('config.fzf').setup()
  require('fzf-lua').fzf_exec(labels, {
    prompt = 'Snippets> ',
    actions = {
      ['enter'] = function(selected)
        local snip = by_label[selected[1]]
        if not snip then
          return
        end
        vim.cmd.startinsert()
        vim.schedule(function()
          ls.snip_expand(snip)
        end)
      end,
    },
  })
end

return M
