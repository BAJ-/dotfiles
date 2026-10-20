-- React hooks. .tsx files always get these; .ts files get them when they
-- import React or are named use* (filetype_extend in plugins/completion.lua)
local ls = require('luasnip')
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local d = ls.dynamic_node
local sn = ls.snippet_node
local rep = require('luasnip.extras').rep
local helpers = require('config.snippets')

local function hook(context, nodes)
  context.condition = helpers.is_react_file
  context.show_condition = helpers.is_react_file
  return s(context, nodes)
end

-- setCount from count
local function setter(args)
  return 'set' .. helpers.upper_first(args[1][1] or '')
end

-- handleKeydown from keydown
local function handler(args)
  local name = ''
  for word in (args[1][1] or ''):gmatch('%w+') do
    name = name .. helpers.upper_first(word)
  end
  return 'handle' .. name
end

-- The type TypeScript's DOM types give each event, by name
local event_types = {
  { '^key', 'KeyboardEvent' },
  { '^pointer', 'PointerEvent' },
  { '^touch', 'TouchEvent' },
  { '^mouse', 'MouseEvent' },
  { 'click$', 'MouseEvent' },
  { '^contextmenu$', 'MouseEvent' },
  { '^wheel$', 'WheelEvent' },
  { '^drag', 'DragEvent' },
  { '^drop$', 'DragEvent' },
  { '^focus', 'FocusEvent' },
  { '^blur$', 'FocusEvent' },
  { '^copy$', 'ClipboardEvent' },
  { '^cut$', 'ClipboardEvent' },
  { '^paste$', 'ClipboardEvent' },
  { '^animation', 'AnimationEvent' },
  { '^transition', 'TransitionEvent' },
  { '^storage$', 'StorageEvent' },
  { '^message$', 'MessageEvent' },
  { '^popstate$', 'PopStateEvent' },
  { '^hashchange$', 'HashChangeEvent' },
  { '^beforeunload$', 'BeforeUnloadEvent' },
}

local function event_type(args)
  local event = args[1][1] or ''
  for _, entry in ipairs(event_types) do
    if event:match(entry[1]) then
      return entry[2]
    end
  end
  return 'Event'
end

return {
  -- useState; the setter's name follows the state's
  hook({ trig = 'us', name = 'useState Hook' }, {
    t('const ['),
    i(1, 'state'),
    t(', '),
    f(setter, { 1 }),
    t('] = useState('),
    i(2),
    t(')'),
  }),

  -- useState with a type
  hook({ trig = 'ust', name = 'useState Hook with a Type' }, {
    t('const ['),
    i(1, 'state'),
    t(', '),
    f(setter, { 1 }),
    t('] = useState<'),
    i(2, 'Type'),
    t('>('),
    i(3),
    t(')'),
  }),

  -- useEffect
  hook({ trig = 'ue', name = 'useEffect Hook' }, {
    t('useEffect(() => {'),
    t({ '', '  ' }),
    i(1),
    t({ '', '}, [' }),
    i(2),
    t('])'),
  }),

  -- useEffect that adds an event listener and removes it again
  hook({ trig = 'uel', name = 'Event Listener Effect' }, {
    t('useEffect(() => {'),
    t({ '', '  const ' }),
    f(handler, { 1 }),
    t(' = (event: '),
    f(event_type, { 1 }),
    t(') => {'),
    t({ '', '    ' }),
    i(3),
    t({ '', '  }' }),
    t({ '', '  ' }),
    i(2, 'window'),
    t(".addEventListener('"),
    i(1, 'keydown'),
    t("', "),
    f(handler, { 1 }),
    t(')'),
    t({ '', '  return () => ' }),
    rep(2),
    t(".removeEventListener('"),
    rep(1),
    t("', "),
    f(handler, { 1 }),
    t(')'),
    t({ '', '}, [' }),
    i(4),
    t('])'),
  }),

  -- useCallback
  hook({ trig = 'ucb', name = 'useCallback Hook' }, {
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
  hook({ trig = 'um', name = 'useMemo Hook' }, {
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
  hook({ trig = 'ur', name = 'useRef Hook' }, {
    t('const '),
    i(1, 'ref'),
    t(' = useRef<'),
    i(2, 'type'),
    t('>('),
    i(3, 'null'),
    t(')'),
  }),

  -- Custom hook named after the file (useWindowSize.ts)
  hook({ trig = 'hook', name = 'Custom Hook' }, {
    t('export const '),
    d(1, function()
      return sn(nil, { i(1, helpers.hook_name()) })
    end),
    t(' = ('),
    i(2),
    t(') => {'),
    t({ '', '  ' }),
    i(3),
    t({ '', '}' }),
  }),
}
