-- Plain JavaScript snippets; TypeScript and TSX files get these too
local ls = require('luasnip')
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

return {
  -- Console log
  s({ trig = 'cl', name = 'Console Log' }, {
    t('console.log('),
    i(1),
    t(')'),
  }),

  -- Try/catch
  s({ trig = 'tc', name = 'Try/Catch' }, {
    t('try {'),
    t({ '', '  ' }),
    i(1),
    t({ '', '} catch (error) {' }),
    t({ '', '  ' }),
    i(2, 'console.error(error)'),
    t({ '', '}' }),
  }),

  -- Export default
  s({ trig = 'ed', name = 'Export Default' }, {
    t('export default '),
    i(1),
  }),
}
