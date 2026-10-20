-- React snippets that write JSX; the TypeScript, JavaScript and React hook
-- snippets are available here too
local ls = require('luasnip')
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local d = ls.dynamic_node
local sn = ls.snippet_node
local rep = require('luasnip.extras').rep
local helpers = require('config.snippets')

-- Get filename without extension for component name
local function filename()
  return vim.fn.expand('%:t:r')
end

-- React 19 renders <Context> as its provider; older versions need .Provider
local function provider()
  local major = helpers.react_major()
  return major and major < 19 and '.Provider' or ''
end

-- The closing tag repeats the element's name, not any attributes typed after it
local function tag_name(args)
  return (args[1][1] or ''):match('^[^%s/>]*')
end

return {
  -- React Functional Component
  s({ trig = 'rfc', name = 'React Functional Component' }, {
    t('interface '),
    f(filename),
    t('Props {'),
    t({ '', '  ' }),
    i(1, '// props'),
    t({ '', '}' }),
    t({ '', '' }),
    t('export default function '),
    f(filename),
    t('({ '),
    i(2),
    t(' }: '),
    f(filename),
    t('Props) {'),
    t({ '', '  return (' }),
    t({ '', '    <div>' }),
    t({ '', '      ' }),
    i(3, 'content'),
    t({ '', '    </div>' }),
    t({ '', '  )' }),
    t({ '', '}' }),
  }),

  -- React Functional Component with "use client"
  s({ trig = 'rfcc', name = 'React Client Component' }, {
    t({ '"use client"', '' }),
    t({ '', 'interface ' }),
    f(filename),
    t('Props {'),
    t({ '', '  ' }),
    i(1, '// props'),
    t({ '', '}' }),
    t({ '', '' }),
    t('export default function '),
    f(filename),
    t('({ '),
    i(2),
    t(' }: '),
    f(filename),
    t('Props) {'),
    t({ '', '  return (' }),
    t({ '', '    <div>' }),
    t({ '', '      ' }),
    i(3, 'content'),
    t({ '', '    </div>' }),
    t({ '', '  )' }),
    t({ '', '}' }),
  }),

  -- Arrow function component named after the file: user-card.tsx -> UserCard
  s({ trig = 'rafc', name = 'React Arrow Function Component' }, {
    t('interface '),
    f(helpers.component_name),
    t('Props {'),
    t({ '', '  ' }),
    i(1),
    t({ '', '}' }),
    t({ '', '' }),
    t({ '', 'export const ' }),
    f(helpers.component_name),
    t(' = ({ '),
    i(2),
    t(' }: '),
    f(helpers.component_name),
    t('Props) => {'),
    t({ '', '  return (' }),
    t({ '', '    <div>' }),
    t({ '', '      ' }),
    i(3),
    t({ '', '    </div>' }),
    t({ '', '  )' }),
    t({ '', '}' }),
  }),

  -- Render a list, with the key React needs
  s({ trig = 'jmap', name = 'Map a List to JSX' }, {
    t('{'),
    i(1, 'items'),
    t('.map(('),
    i(2, 'item'),
    t(') => ('),
    t({ '', '  <' }),
    i(3, 'li'),
    t(' key={'),
    rep(2),
    t('.id}>'),
    i(4),
    t('</'),
    f(tag_name, { 3 }),
    t('>'),
    t({ '', '))}' }),
  }),

  -- Context, its provider, and a hook that fails clearly outside the provider.
  -- The name comes from the file (ThemeContext.tsx -> Theme) and fills in everywhere.
  s({ trig = 'ctx', name = 'Context with Provider and Hook' }, {
    t('interface '),
    d(1, function()
      return sn(nil, { i(1, helpers.context_name()) })
    end),
    t('ContextValue {'),
    t({ '', '  ' }),
    i(2),
    t({ '', '}' }),
    t({ '', '' }),
    t({ '', 'const ' }),
    rep(1),
    t('Context = createContext<'),
    rep(1),
    t('ContextValue | null>(null)'),
    t({ '', '' }),
    t({ '', 'export const ' }),
    rep(1),
    t('Provider = ({ children }: { children: React.ReactNode }) => {'),
    t({ '', '  const value = { ' }),
    i(3),
    t(' }'),
    t({ '', '  return <' }),
    rep(1),
    t('Context'),
    f(provider),
    t(' value={value}>{children}</'),
    rep(1),
    t('Context'),
    f(provider),
    t('>'),
    t({ '', '}' }),
    t({ '', '' }),
    t({ '', 'export const use' }),
    rep(1),
    t(' = () => {'),
    t({ '', '  const context = useContext(' }),
    rep(1),
    t('Context)'),
    t({ '', "  if (!context) throw new Error('use" }),
    rep(1),
    t(' must be used inside '),
    rep(1),
    t("Provider')"),
    t({ '', '  return context' }),
    t({ '', '}' }),
  }),
}
