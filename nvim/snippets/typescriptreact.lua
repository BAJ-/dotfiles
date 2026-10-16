-- React snippets; TypeScript and JavaScript snippets are available here too
local ls = require('luasnip')
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node

-- Get filename without extension for component name
local function filename()
  return vim.fn.expand('%:t:r')
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

  -- useState
  s({ trig = 'us', name = 'useState Hook' }, {
    t('const ['),
    i(1, 'state'),
    t(', set'),
    i(2, 'State'),
    t('] = useState'),
    t('<'),
    i(3, 'type'),
    t('>('),
    i(4, 'initial'),
    t(')'),
  }),

  -- useEffect
  s({ trig = 'ue', name = 'useEffect Hook' }, {
    t('useEffect(() => {'),
    t({ '', '  ' }),
    i(1),
    t({ '', '}, [' }),
    i(2),
    t('])'),
  }),

  -- useCallback
  s({ trig = 'ucb', name = 'useCallback Hook' }, {
    t('const '),
    i(1, 'fn'),
    t(' = useCallback(('),
    i(2),
    t(') => {'),
    t({ '', '  ' }),
    i(3),
    t({ '', '}, [' }),
    i(4),
    t('])'),
  }),

  -- useMemo
  s({ trig = 'um', name = 'useMemo Hook' }, {
    t('const '),
    i(1, 'value'),
    t(' = useMemo(() => {'),
    t({ '', '  return ' }),
    i(2),
    t({ '', '}, [' }),
    i(3),
    t('])'),
  }),

  -- useRef
  s({ trig = 'ur', name = 'useRef Hook' }, {
    t('const '),
    i(1, 'ref'),
    t(' = useRef<'),
    i(2, 'type'),
    t('>('),
    i(3, 'null'),
    t(')'),
  }),

  -- Arrow function component
  s({ trig = 'arfc', name = 'Arrow Function Component' }, {
    t('interface '),
    f(filename),
    t('Props {'),
    t({ '', '  ' }),
    i(1, '// props'),
    t({ '', '}' }),
    t({ '', '' }),
    t('export const '),
    f(filename),
    t(': React.FC<'),
    f(filename),
    t('Props> = ({ '),
    i(2),
    t(' }) => {'),
    t({ '', '  return (' }),
    t({ '', '    <div>' }),
    t({ '', '      ' }),
    i(3, 'content'),
    t({ '', '    </div>' }),
    t({ '', '  )' }),
    t({ '', '}' }),
  }),
}
