-- JavaScript snippets; every JS and TS file gets these
local ls = require('luasnip')
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local postfix = require('luasnip.extras.treesitter_postfix')
local helpers = require('config.snippets')

-- What a postfix snippet wraps: the largest of these that ends at the dot, so
-- `a.b().c.log` takes the whole chain but `f(a.b.log)` only `a.b`
local operands = {
  'identifier',
  'member_expression',
  'call_expression',
  'subscript_expression',
  'new_expression',
  'parenthesized_expression',
  'non_null_expression',
  'this',
  'string',
  'template_string',
  'number',
  'true',
  'false',
  'null',
  'undefined',
  'array',
}
-- Also whole comparisons and `await x`; .await leaves these out so
-- `a + b.await` gives `a + await b`
local expressions = vim.list_extend({
  'await_expression',
  'binary_expression',
  'unary_expression',
  'ternary_expression',
  'as_expression',
  'satisfies_expression',
}, operands)

-- LuaSnip indents every line after the first, so take the matched lines'
-- original indentation off first
local function expression(_, parent)
  local lines = parent.snippet.env.LS_TSMATCH
  if type(lines) ~= 'table' then
    return ''
  end
  local indent = parent.indentstr or ''
  return vim.tbl_map(function(line)
    return line:sub(1, #indent) == indent and line:sub(#indent + 1) or line
  end, lines)
end

local function wrap(trig, name, types, docstring, nodes)
  return postfix.treesitter_postfix({
    trig = trig,
    name = name,
    docstring = docstring,
    matchTSNode = postfix.builtin.tsnode_matcher.find_topmost_types(types),
    reparseBuffer = 'live',
    show_condition = helpers.after_expression,
  }, nodes)
end

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

  -- Async function; TypeScript infers the return type
  s({ trig = 'af', name = 'Async Function' }, {
    t('async function '),
    i(1, 'name'),
    t('('),
    i(2),
    t(') {'),
    t({ '', '  ' }),
    i(3),
    t({ '', '}' }),
  }),

  -- Arrow function
  s({ trig = 'arf', name = 'Arrow Function' }, {
    t('const '),
    i(1, 'name'),
    t(' = ('),
    i(2),
    t(') => {'),
    t({ '', '  ' }),
    i(3),
    t({ '', '}' }),
  }),

  -- throw new Error(`...`)
  s({ trig = 'tne', name = 'Throw New Error' }, {
    t('throw new Error(`'),
    i(1, 'message'),
    t('`)'),
  }),

  -- fetch only rejects on network errors, so check the status before parsing
  s({ trig = 'fetchj', name = 'Fetch JSON' }, {
    t('const response = await fetch('),
    i(1, 'url'),
    t(')'),
    t({ '', 'if (!response.ok) throw new Error(`Request failed: ${response.status}`)' }),
    t({ '', 'const ' }),
    i(2, 'data'),
    t(' = await response.json()'),
  }),

  -- Promise.all with destructuring
  s({ trig = 'pa', name = 'Promise.all' }, {
    t('const ['),
    i(1, 'a, b'),
    t('] = await Promise.all(['),
    i(2),
    t('])'),
  }),

  -- Postfix: type these right after an expression
  wrap('.log', 'Log the expression', expressions, 'console.log(expression)', {
    t('console.log('),
    f(expression),
    t(')'),
  }),
  wrap('.await', 'Await the expression', operands, 'await expression', {
    t('await '),
    f(expression),
  }),
  wrap('.return', 'Return the expression', expressions, 'return expression', {
    t('return '),
    f(expression),
  }),
  wrap('.const', 'Store the expression in a const', expressions, 'const name = expression', {
    t('const '),
    i(1, 'name'),
    t(' = '),
    f(expression),
  }),
  wrap('.if', 'If the expression', expressions, { 'if (expression) {', '  ', '}' }, {
    t('if ('),
    f(expression),
    t(') {'),
    t({ '', '  ' }),
    i(1),
    t({ '', '}' }),
  }),
}
