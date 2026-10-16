-- Pick changed/new files from `git status` (fzf-lua, Tab to multi-select)
-- and open them side by side.
local M = {}

---Lay files out on screen: 1 fills the window, 2 side by side, 3 is one on
---top and two below, 4+ is a grid with the extra file in the top row.
---@param files string[] absolute paths
function M.open_in_layout(files)
  if #files == 0 then
    return
  end

  -- Build the layout without the tree, then bring it back on the left
  local ok_tree, tree = pcall(require, 'nvim-tree.api')
  local tree_was_open = ok_tree and tree.tree.is_visible()
  if tree_was_open then
    tree.tree.close()
  end

  vim.cmd.only({ mods = { silent = true, emsg_silent = true } })
  vim.cmd.edit(vim.fn.fnameescape(files[1]))
  local first = vim.api.nvim_get_current_win()

  -- files in the top row: 2 side by side, 3 as one over two, 4+ split evenly
  local top = #files == 3 and 1 or #files == 2 and 2 or math.ceil(#files / 2)
  for i = 2, top do
    vim.cmd.vsplit(vim.fn.fnameescape(files[i]))
  end
  if #files > top then
    vim.cmd('botright split ' .. vim.fn.fnameescape(files[top + 1]))
    for i = top + 2, #files do
      vim.cmd.vsplit(vim.fn.fnameescape(files[i]))
    end
  end

  if tree_was_open then
    tree.tree.open({ focus = false })
  end
  vim.cmd.wincmd('=')
  vim.api.nvim_set_current_win(first)
end

function M.pick()
  local fzf = require('fzf-lua')
  fzf.git_status({
    prompt = 'Changed files> ',
    actions = {
      ['enter'] = function(selected, opts)
        local files, skipped = {}, 0
        for _, entry in ipairs(selected) do
          local path = require('fzf-lua.path').entry_to_file(entry, opts).path
          if path and not vim.startswith(path, '/') then
            path = vim.fs.joinpath(opts.cwd or vim.uv.cwd(), path)
          end
          -- deleted files show up in git status but can't be opened
          if path and vim.uv.fs_stat(path) then
            files[#files + 1] = vim.fs.normalize(path)
          else
            skipped = skipped + 1
          end
        end
        if skipped > 0 then
          vim.notify(('Skipped %d deleted file(s)'):format(skipped))
        end
        M.open_in_layout(files)
      end,
    },
  })
end

return M
