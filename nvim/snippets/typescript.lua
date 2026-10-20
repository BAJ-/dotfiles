-- TypeScript-only snippets (typed syntax); TSX files get these too
local ls = require('luasnip')
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local rep = require('luasnip.extras').rep

return {
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

  -- Type guard: the type name fills in both places
  s({ trig = 'guard', name = 'Type Guard' }, {
    t('function is'),
    i(1, 'Type'),
    t('(value: unknown): value is '),
    rep(1),
    t(' {'),
    t({ '', '  return ' }),
    i(2),
    t({ '', '}' }),
  }),
}
