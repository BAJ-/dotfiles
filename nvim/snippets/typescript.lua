-- TypeScript-only snippets (typed syntax); TSX files get these too
local ls = require('luasnip')
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

return {
  -- Async function
  s({ trig = 'af', name = 'Async Function' }, {
    t('async function '),
    i(1, 'name'),
    t('('),
    i(2),
    t('): Promise<'),
    i(3, 'void'),
    t('> {'),
    t({ '', '  ' }),
    i(4),
    t({ '', '}' }),
  }),

  -- Interface
  s({ trig = 'int', name = 'Interface' }, {
    t('interface '),
    i(1, 'Name'),
    t(' {'),
    t({ '', '  ' }),
    i(2),
    t({ '', '}' }),
  }),

  -- Type
  s({ trig = 'tp', name = 'Type Alias' }, {
    t('type '),
    i(1, 'Name'),
    t(' = {'),
    t({ '', '  ' }),
    i(2),
    t({ '', '}' }),
  }),

  -- Arrow function
  s({ trig = 'arf', name = 'Arrow Function' }, {
    t('const '),
    i(1, 'name'),
    t(' = ('),
    i(2),
    t('): '),
    i(3, 'void'),
    t(' => {'),
    t({ '', '  ' }),
    i(4),
    t({ '', '}' }),
  }),
}
