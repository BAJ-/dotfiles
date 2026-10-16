-- Picks the TypeScript language server per project: TypeScript 7's native
-- server (`tsc --lsp`) when the project's own typescript is 7+, vtsls
-- otherwise. TS 7 has no language-service plugins yet (e.g. Next.js's), so
-- projects stay on vtsls until they upgrade typescript themselves.
local M = {}

local majors = {} ---@type table<string, integer|false>

---Major version of the typescript package a file resolves (nearest node_modules)
---@param path string
---@return integer?
function M.major(path)
  for dir in vim.fs.parents(path) do
    local pkg = dir .. '/node_modules/typescript/package.json'
    if majors[pkg] ~= nil then
      return majors[pkg] or nil
    end
    if vim.uv.fs_stat(pkg) then
      local ok, data = pcall(vim.json.decode, table.concat(vim.fn.readfile(pkg), '\n'))
      local major = ok and tonumber(tostring(data.version or ''):match('^(%d+)')) or nil
      majors[pkg] = major or false
      return major
    end
  end
end

---@param buf integer
---@return boolean
function M.native(buf)
  local major = M.major(vim.api.nvim_buf_get_name(buf))
  return major ~= nil and major >= 7
end

return M
