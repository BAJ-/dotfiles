# dotfiles

My Mac setup for frontend work: zsh, plus Neovim 0.12 set up for TypeScript, React, Next.js, Vite and Electron, with tests, debugging and AI built in. One script sets up a new Mac or brings an existing one up to date.

**Contents:** [Set up a Mac](#set-up-a-mac) · [Reading the keys](#reading-the-keys) · [Cheat sheet](#cheat-sheet) · Workflows: [Find](#find-files-and-text) · [Move around](#move-around) · [Code](#understand-and-change-code) · [Write](#write-code) · [Save](#save-and-format) · [Git](#git) · [Tests](#run-tests) · [Debug](#debug) · [AI](#ai) · [Shell](#terminal-and-shell) · [Updates](#keep-it-up-to-date) · [Key index](#key-index) · [Where things live](#where-things-live)

## Set up a Mac

```sh
git clone https://github.com/BAJ-/dotfiles.git ~/projects/dotfiles   # any folder works
cd ~/projects/dotfiles
./setup.sh --dry-run   # lists what would change
./setup.sh
```

`setup.sh` works on a new Mac and on one that's already set up. Every step checks first, so a second run changes nothing and says "Everything is up to date". It:

- installs Homebrew if needed, then everything in the [Brewfile](Brewfile) (Neovim, tree-sitter-cli, ripgrep, fd, fzf, fnm, Go, gh, starship, tig, shellcheck, Hack Nerd Font), upgrading anything outdated
- links `~/.zshrc`, `~/z.sh`, `~/.config/starship.toml` and `~/.config/nvim` to this repo; your own files are moved to `~/.dotfiles-backup/<date-time>/` first
- makes the latest Node LTS (through fnm) the default
- removes the old setup (nvm, gvm, Rye, vim-plug, old Neovim data), moving global npm packages and npm settings (to `~/.npmrc`) across first
- installs Neovim's plugins at the versions in [nvim/nvim-pack-lock.json](nvim/nvim-pack-lock.json), plus the Treesitter parsers and language servers

It ends with a summary of what changed and anything left for you, such as signing in to Copilot (`:LspCopilotSignIn` in Neovim).

## Reading the keys

- **The leader key is `,`**: `,ff` means press `,`, then `f`, then `f`.
- `<C-v>` is Ctrl+v, `<S-Tab>` is Shift+Tab and `<M-]>` is Option+]. Option keys need iTerm2 › Settings › Profiles › Keys › General › Left Option key set to **Esc+**.
- Keys work in normal mode unless marked *insert*, *visual* or *terminal*.
- **Forgot a key?** Press `,` (or `g`, `z`, `[`, `]`, `<C-w>`, `"`, `'`) and wait: a popup lists everything that can follow. Inside plugin windows, `g?` (file tree, debug view, Mason), `?` (test summary, AI chat) or `F1` (pickers) lists that window's keys.

## Cheat sheet

| Keys | Does |
| --- | --- |
| `,ff` / `,fg` | Find a file / search text (`useState -- *.tsx` searches only .tsx files) |
| `,fr` | Back to the last picker, as you left it |
| `,tt` / `,n` | File tree / show the current file in it |
| `s` | Jump anywhere on screen: type a character or two, then the label |
| `gd` / `K` | Go to definition / show docs |
| `,cr` / `grn` | References / rename everywhere |
| `,ca` | Code action: quick fix, add import… |
| `]d` / `[d` | Next / previous problem |
| `Tab` *(insert)* | Next completion item, else accept the AI suggestion, else next snippet field |
| `gcc` | Comment the line (`gc` + a motion or selection for more) |
| `,mr` / `,ma` | Run the test under the cursor / the whole file |
| `,db`, then `,ds` | Set a breakpoint, then start debugging |
| `]h` / `,gp` / `,gs` | Next git change / preview it / stage it |
| `,gf` | Open your changed files side by side |
| `,aa` / `,ac` | AI agent in a split / AI chat |
| `Space` | Command line (same as `:`) |
| `jj` *(insert)* | Back to normal mode |

## Workflows

### Find files and text

`,fg` searches file contents as you type. To limit which files it searches, add ` -- ` and globs: `useState -- *.tsx !*.test.*` (`!` excludes).

| Keys | Does |
| --- | --- |
| `,ff` | Files (without hidden or git-ignored ones; `<M-h>` / `<M-i>` in the picker adds them) |
| `,fg` | Search text, optionally in some files only (see above) |
| `,fb` | Open buffers |
| `,fh` | Neovim help |
| `,fr` | Resume the last picker |
| `,fn` | Copy the current file's name |
| `,gf` | Changed files from git (see [Git](#git)) |

Inside a picker:

| Keys | Does |
| --- | --- |
| `Enter` | Open (with several marked: send them to the quickfix list) |
| `<C-v>` / `<C-s>` / `<C-t>` | Open in a vertical split / horizontal split / new tab |
| `Tab` / `<S-Tab>` | Mark the entry and move down / up |
| `<M-a>` | Mark all |
| `<M-q>` | Send the marked entries to the quickfix list (`<M-Q>`: location list) |
| `<M-h>` / `<M-i>` / `<M-f>` | Include hidden files / git-ignored files / follow symlinks |
| `<C-f>` / `<C-b>` | Half a page down / up |
| `<S-Down>` / `<S-Up>` | Scroll the preview |
| `F4` / `F2` | Preview on/off / full screen |
| `F1` | All picker keys |
| `Esc` | Close (`<M-Esc>` hides it instead; `,fr` brings it back) |

### Move around

**File tree.** `,tt` opens or closes it, `,n` opens it at the current file and `,r` refreshes it. Renaming or moving a file in the tree updates the imports that point to it. `nvim some/folder` starts with the tree open.

| In the tree | Does |
| --- | --- |
| `Enter` / `o` | Open the file (or expand the folder) |
| `<C-v>` / `<C-x>` / `<C-t>` | Open in a vertical split / horizontal split / new tab |
| `Tab` | Preview, keeping the tree focused |
| `a` | New file; end the name with `/` for a folder |
| `r` | Rename (`e` keeps the extension, `u` edits the full path) |
| `d` | Delete |
| `x` / `c` / `p` | Cut / copy / paste |
| `y` / `Y` / `gy` | Copy the name / relative path / absolute path |
| `H` / `I` | Show or hide dotfiles / git-ignored files |
| `f` / `F` | Filter by name / clear the filter |
| `W` / `E` | Collapse / expand everything |
| `P` | Go to the parent folder |
| `-` / `<C-]>` | Make the parent / the folder under the cursor the tree's root |
| `]c` / `[c` | Next / previous changed file |
| `]e` / `[e` | Next / previous file with problems |
| `q` | Close |
| `g?` | All tree keys |

**Jumping**

| Keys | Does |
| --- | --- |
| `s` | Jump: type the characters at the target, then its label. After an operator it acts up to there (`d` then `s`) |
| `S` | Select a syntax node (a JSX element, an argument, a function…) by its label; also after an operator |
| `f` `t` `F` `T` | Find a character, across lines. Press `f` again for the next match, `F` for the previous; `;` also repeats. `,` is the leader, so it doesn't repeat backwards |
| `<C-o>` / `Tab` | Back / forward through places you've been (`Tab` first takes a pending [edit suggestion](#ai)) |
| `%` | Jump between matching brackets, or JSX/HTML tags |
| `gx` | Open the link or file under the cursor in its app |
| `n` / `N` | Next / previous search match, centred on screen |

`s` and `S` replace Vim's own substitute commands; `cl` and `cc` still do those.

**Windows, buffers and tabs**

| Keys | Does |
| --- | --- |
| `,h` `,j` `,k` `,l` | Go to the window left / below / above / right |
| `,sv` / `,sh` | Split vertically / horizontally |
| `,bh` | Close the window (the file stays open) |
| `,bk` | Close the file but keep the window layout; asks first if it has unsaved changes |
| `[b` / `]b` | Previous / next buffer |
| `,tc` / `,tn` / `,tp` | New / next / previous tab |
| `<C-w>` | Wait for all window commands (resize, swap, maximise…) |

**Lists.** `]q` / `[q` go to the next / previous quickfix entry, and `]Q` / `[Q` to the last / first. `]l` / `[l` do the same for the location list. Pickers fill these lists with `<M-q>`; `grr` and `gO` use them too.

### Understand and change code

Language servers start on their own for TypeScript and JavaScript, ESLint, CSS and SCSS, CSS Modules (`styles.` completes class names and `gd` jumps to the class), CSS variables, HTML, JSON, YAML, Lua and Bash. TypeScript projects on TypeScript 7 or later get TypeScript's own `tsc --lsp`; older ones get vtsls. If a server gets stuck, `:lsp restart` restarts it.

| Keys | Does |
| --- | --- |
| `gd` (or `,cd`) | Go to definition |
| `,cv` / `,ch` | Definition in a vertical / horizontal split |
| `,ct` (or `grt`) | Type definition |
| `gri` | Implementations |
| `,cr` | References, in a picker (`grr`: in the quickfix list) |
| `,cs` | Symbols in this file, in a picker (`gO`: outline in the location list) |
| `K` | Docs for what's under the cursor; `K` again moves into them |
| `<C-s>` *(insert)* | Signature of the function you're calling |
| `,ca` (or `gra`) | Code action: quick fix, add the missing import… (also on a selection) |
| `grn` | Rename the symbol in every file |
| `grx` | Run the code lens on this line |
| `,ci` | Inlay hints on/off (parameter names, inferred types) |

**Problems (diagnostics)**

| Keys | Does |
| --- | --- |
| `]d` / `[d` | Next / previous problem |
| `]D` / `[D` | Last / first problem in the file |
| `,en` / `,ep` | Next / previous problem, with its message, centred |
| `,ed` (or `<C-w>d`) | Full message for the problem under the cursor |

Failing tests show up as problems too, on the failing line.

### Write code

The completion menu appears as you type, with suggestions from the language server, file paths, snippets and words in the file.

| Keys *(insert)* | Does |
| --- | --- |
| `Tab` | Menu open: next item. Otherwise: accept the AI suggestion, else go to the next snippet field, else a tab |
| `<S-Tab>` | Previous item, or the previous snippet field |
| `<C-n>` / `<C-p>` (or `Down` / `Up`) | Next / previous item |
| `Enter` | Accept the selected item; with nothing selected, a new line |
| `<C-e>` | Close the menu |
| `<C-Space>` | Open the menu; press again to show or hide the docs |
| `<C-f>` / `<C-b>` | Scroll the docs |
| `<C-k>` | Show or hide the signature |

**Snippets.** Type a trigger and pick it in the menu. Every snippet, and how to use them, is in [Snippets](#snippets).

**Editing**

| Keys | Does |
| --- | --- |
| `gcc` | Comment or uncomment the line (JSX-aware) |
| `gc` + motion, or `gc` *(visual)* | Comment a range (`gcip`: the paragraph) |
| `dgc` | Delete the comment block under the cursor |
| `S`, or `an` / `in` *(visual)* | Select by syntax: grow to the enclosing node / shrink to an inner one |
| `]n` / `[n` *(visual)* | Select the next / previous node (`]N` / `[N`: next / previous sibling) |
| `]<Space>` / `[<Space>` | Add an empty line below / above |
| `F5` | Remove trailing whitespace in the file |
| `>` *(insert)* | Finishing an opening JSX/HTML tag adds its closing tag; renaming a tag renames its pair |

### Snippets

Type a trigger and pick it in the completion menu, then fill in its fields:

- The first field is selected, so typing replaces it. `Tab` / `<S-Tab>` go to the next / previous field; if the menu is open, close it with `<C-e>` first.
- Names that depend on a field change as you type it, like the setter in `us` or the closing tag in `jmap`.
- Moving the cursor out of a snippet ends it, so a later `Tab` doesn't jump back into it.
- Snippets don't add imports. Put the cursor on the name that needs one and press `,ca`.
- `,ss` lists every snippet for the file type, with the file it comes from.

**JavaScript and TypeScript files**

| Trigger | Writes | Fields, in order |
| --- | --- | --- |
| `cl` | `console.log(…)` | value |
| `tc` | `try { … } catch (error) { console.error(error) }` | body, catch body |
| `ed` | `export default …` | value |
| `af` | `async function name(…) { … }` | name, parameters, body |
| `arf` | `const name = (…) => { … }` | name, parameters, body |
| `tne` | ``throw new Error(`message`)`` | message |
| `pa` | `const [a, b] = await Promise.all([…])` | names, promises |
| `fetchj` | `fetch`, an error unless `response.ok`, then the JSON | URL, name for the data |

`af` and `arf` leave out the return type, so TypeScript works it out.

```ts
// fetchj
const response = await fetch(url)
if (!response.ok) throw new Error(`Request failed: ${response.status}`)
const data = await response.json()
```

**TypeScript files**

| Trigger | Writes | Fields, in order |
| --- | --- | --- |
| `int` | `interface Name { … }` | name, members |
| `tp` | `type Name = { … }` | name, members |
| `guard` | `function isUser(value: unknown): value is User { return … }` | type (written in both places), the check |

**React hooks**: in .tsx files, and in .ts files that import from `'react'` or are named `use…` (`useWindowSize.ts`, `use-window-size.ts`)

| Trigger | Writes | Fields, in order |
| --- | --- | --- |
| `us` | `const [count, setCount] = useState(…)` | name (the setter follows), initial value |
| `ust` | `const [user, setUser] = useState<User \| null>(…)` | name, type, initial value |
| `ue` | `useEffect(() => { … }, [])` | body, dependencies |
| `uel` | An effect that adds an event listener and removes it again | event (the handler's name and the event's type follow), target, handler body, dependencies |
| `ucb` | `const fn = useCallback((…) => { … }, [])` | name, parameters, body, dependencies |
| `um` | `const value = useMemo(() => { return … }, [])` | name, value, dependencies |
| `ur` | `const ref = useRef<type>(null)` | name, type, initial value |
| `hook` | `export const useWindowSize = (…) => { … }` | name (from the file, else `useName`), parameters, body |

`uel` types the event from its name: `keydown` gives `KeyboardEvent`, `click` gives `MouseEvent`, and any event it doesn't know gives `Event`.

```tsx
// uel: type "resize", Tab past "window", then write the handler
useEffect(() => {
  const handleResize = (event: Event) => {
    setWidth(window.innerWidth)
  }
  window.addEventListener('resize', handleResize)
  return () => window.removeEventListener('resize', handleResize)
}, [])
```

**React components**: in .tsx files

| Trigger | Writes | Fields, in order |
| --- | --- | --- |
| `rafc` | Arrow component named after the file, with its `Props` interface | props interface, props, JSX |
| `rfc` | `export default function` component named after the file, with its `Props` interface | props interface, props, JSX |
| `rfcc` | `rfc` with `"use client"` on top, for Next.js | props interface, props, JSX |
| `jmap` | `{items.map((item) => (<li key={item.id}></li>))}` | list, item (the key follows), element (the closing tag follows), content |
| `ctx` | A context, its provider, and a hook that throws when used outside the provider | name (written everywhere), value type, value |

- `rafc` turns the file name into PascalCase (`user-card.tsx` gives `UserCard`) and uses the folder's name for `index.tsx`. `rfc` and `rfcc` use the file name as it is.
- `ctx` starts with the file's name minus `Context` or `Provider` (`ThemeContext.tsx` gives `Theme`). It writes `<ThemeContext value={value}>` for React 19 and later and `<ThemeContext.Provider value={value}>` before that, going by the React installed in the project, else the version in its package.json.

```tsx
// rafc in user-card.tsx
interface UserCardProps {
  name: string
}

export const UserCard = ({ name }: UserCardProps) => {
  return (
    <div>
      {name}
    </div>
  )
}
```

```tsx
// ctx in ThemeContext.tsx, on React 19
interface ThemeContextValue {
  dark: boolean
}

const ThemeContext = createContext<ThemeContextValue | null>(null)

export const ThemeProvider = ({ children }: { children: React.ReactNode }) => {
  const value = { dark: true }
  return <ThemeContext value={value}>{children}</ThemeContext>
}

export const useTheme = () => {
  const context = useContext(ThemeContext)
  if (!context) throw new Error('useTheme must be used inside ThemeProvider')
  return context
}
```

**After an expression**: type these straight after an expression, in JavaScript and TypeScript files

| Trigger | Turns | Into |
| --- | --- | --- |
| `.log` | `user.name.log` | `console.log(user.name)` |
| `.await` | `res.json().await` | `await res.json()` |
| `.return` | `getUser(id).return` | `return getUser(id)` |
| `.const` | `items.filter(isOpen).const` | `const name = items.filter(isOpen)`, with `name` selected |
| `.if` | `user.isAdmin.if` | `if (user.isAdmin) { … }` |

- They take the whole expression that ends at the dot, including call chains over several lines: `a.b().c.log` logs `a.b().c`, and `fn(a.b.log)` logs `a.b`.
- `.log`, `.return`, `.const` and `.if` also take comparisons, `!x` and `await x` (`a > b.if` gives `if (a > b)`). `.await` takes only the last part (`a + b.await` gives `a + await b`).
- The menu offers them only straight after `expression.`, not in comments, strings or JSX text. Typing part of the trigger is enough: `user.lo`, then pick `.log`.

### Save and format

- **Autosave.** A file is saved a second after you stop changing it (in normal mode or when you leave insert mode), and when Neovim loses focus, so dev servers reload without `:w`. It never saves while you're typing.
- **Formatting on save.** Prettier formats JS, TS, CSS, SCSS, HTML, JSON, Markdown, YAML and GraphQL. A manual `:w` runs ESLint's fixes first; autosave doesn't, so an import you haven't used yet isn't removed while you work.
- `:Format` formats now and `:LspEslintFixAll` applies ESLint's fixes now. Lua is formatted with stylua, but only in projects with a stylua config.
- Files changed outside Neovim (git, AI agents) reload when you come back to them. Undo history survives closing a file.

### Git

| Keys | Does |
| --- | --- |
| `]h` / `[h` | Next / previous change in the file |
| `,gp` | Preview the change |
| `,gs` / `,gr` | Stage / reset the change |
| `,gb` | Blame the line, with the full commit message |
| `,gd` | Diff the file against the index, side by side |
| `,gf` | Pick changed files (`Tab` marks several); `Enter` opens them side by side: 2 next to each other, 3 as one over two, more in a grid |
| `:DiffTool a b` | Compare two folders or files |

The file tree marks changed files (✗ changed, ✓ staged, ★ new). For anything more, run `tig` or `gh` in a terminal (`,tm`).

### Run tests

The same keys work for Vitest, Jest and Playwright, and each test runs with its own package's runner and config, monorepos included.

| Keys | Does |
| --- | --- |
| `,mr` | Run the test under the cursor |
| `,ma` | Run the whole file |
| `,ml` | Run the last tests again |
| `,md` | Debug the test under the cursor (set breakpoints first) |
| `,mw` | Watch the file: run it again on every save |
| `,mx` | Stop |
| `,mo` | Output of the test under the cursor |
| `,mO` | Output panel |
| `,ms` | Summary of all tests |

Vitest and Jest results appear next to each test, and failures as problems on the failing line (`]d` gets there). Playwright specs (files that import `@playwright/test`) run in a terminal below so you can follow along. Two keys are just for them:

| Keys | Does |
| --- | --- |
| `,mu` | Playwright UI mode |
| `,mi` | Run the test under the cursor in a visible browser with the Playwright Inspector, paused |

In the summary (`,ms`):

| Keys | Does |
| --- | --- |
| `r` / `d` | Run / debug the test or file under the cursor |
| `o` / `O` | Output / short output |
| `i` | Jump to the test |
| `J` / `K` | Next / previous failed test |
| `w` | Watch |
| `m`, then `R` / `D` | Mark tests, then run / debug the marked ones (`M` clears the marks) |
| `u` | Stop |
| `Enter` / `e` | Expand / expand everything |
| `?` | All summary keys |

### Debug

1. `,db` sets a breakpoint on the line (`,dB` asks for a condition).
2. `,ds` starts: pick a configuration, and the debug view opens.
3. Step with `,dn` (over), `,di` (into) and `,do` (out); `,dc` continues and `,dl` shows the value under the cursor.
4. `,de` ends everything, child processes included, and clears the breakpoints. `,dr` runs the last configuration again.

| Configuration | For |
| --- | --- |
| Node: current file | The open JS or TS file (Node runs TypeScript directly) |
| Vitest / Jest / Playwright: current file | The open test file (`,md` debugs just the test under the cursor) |
| Next.js: server (dev script) | Starts the dev script (npm, pnpm, yarn or bun, from the lockfile) under the debugger: route handlers, server components |
| Next.js: client in Chrome (:3000) | With the dev server running, opens Chrome to debug client components |
| Vite: client in Chrome (:5173) | The same for a Vite app |
| Electron: main + renderer | Starts the app and debugs both processes (Electron Forge projects start through Forge) |
| Electron: main process / renderer (attach :9222) | Just one of them |
| Node: attach to :9229 / attach to a process | A process started with `--inspect` / any running Node process |

Projects with a `.vscode/launch.json` get its configurations too. In Electron Forge + Vite projects, main-process breakpoints need `build: { sourcemap: true }` in `vite.main.config.*`; you get a warning when it's missing.

| Keys | Does |
| --- | --- |
| `,db` / `,dB` | Breakpoint / conditional breakpoint |
| `,ds` | Start, or continue |
| `,dc` | Continue |
| `,dn` / `,di` / `,do` | Step over / into / out |
| `,dl` | Value under the cursor |
| `,dv` | Debug view on/off |
| `,dr` | Run the last configuration again |
| `,dC` | Clear all breakpoints |
| `,de` | End all debugging and clear breakpoints |

In the debug view:

| Keys | Does |
| --- | --- |
| `S` / `W` / `B` / `E` / `T` / `R` | Scopes / watches / breakpoints / exceptions / threads / REPL |
| `]v` / `[v` | Next / previous view (`]V` / `[V`: last / first) |
| `Enter` | Expand a variable, jump to a frame or breakpoint, or toggle an exception filter |
| `i` / `a` | Add a watch expression |
| `e` / `d` | Edit / delete a watch expression |
| `s` / `c` | Set / copy a value |
| `[[` | Jump to the parent |
| `g?` | All debug view keys |

### AI

Copilot works once you've signed in (`:LspCopilotSignIn`, once per Mac). When Ollama is running with the right model pulled, the local model is used instead; nothing local is installed by default. `:AIStatus` shows what's active and why.

**While typing,** suggestions appear as grey ghost text:

| Keys | Does |
| --- | --- |
| `Tab` *(insert)* | Accept (when the completion menu is closed) |
| `<M-]>` / `<M-[>` *(insert)* | Next / previous suggestion |
| `,al` | Switch ghost text between Copilot and the local model |
| `Tab` *(normal)* | Jump to the next edit Copilot suggests in the file, then apply it |
| `,an` | Next edit suggestions on/off |

**Agent in a split.** This is Copilot CLI next to your code; `,aa` runs it on the local model when one is available.

| Keys | Does |
| --- | --- |
| `,aa` | Open or close the agent (local model first) |
| `,ag` | The same, always on GitHub's models |
| `,as` | Choose the agent CLI |
| `,at` | Send this spot (or the selection) to the agent |
| `,af` | Send the file |
| `,av` *(visual)* | Send the selection |
| `,ap` | Prompts: explain, fix, review, tests, optimize, document… |

In the agent window:

| Keys | Does |
| --- | --- |
| `<C-q>` | To normal mode, to scroll or copy; in normal mode it hides the agent |
| `q` *(normal)* | Hide the agent (it keeps running) |
| `<C-z>` | Back to your code, keeping the agent visible |
| `<C-p>` | Insert a prompt or context |
| `<C-f>` / `<C-b>` | Pick a file / buffer to add |
| `<C-h>` | Go to the window on the left |

**Chat.** `,ac` opens a chat. It uses the local model if available, else Copilot CLI, else Copilot, and tells you which. On a selection, `,ac` adds it to the chat instead.

| Keys (in the chat) | Does |
| --- | --- |
| `Enter` / `<C-s>` | Send (`<C-s>` in insert mode) |
| `q` | Stop the answer |
| `<C-c>` | Close the chat |
| `ga` | Change the model or backend |
| `gr` | Regenerate the last answer |
| `gy` | Copy the last code block |
| `gx` | Clear the chat |
| `]]` / `[[` | Next / previous message |
| `{` / `}` | Previous / next chat |
| `?` | All chat keys |

When the chat proposes edits: `g2` accepts, `g3` rejects, `g1` accepts everything in this file from now on, `gv` shows the diff, `}` / `{` move between changes and `g4` cancels.

**Local models (optional).** Run `brew install ollama` and `ollama serve`, then `ollama pull qwen3-coder:30b` for chat and the agent, and `ollama pull qwen2.5-coder:7b` for ghost text. Other models: set `AI_LOCAL_MODEL` / `AI_LOCAL_FIM_MODEL`. Another machine: set `OLLAMA_HOST`.

### Terminal and shell

| Keys or command | Does |
| --- | --- |
| `,tm` | Terminal in the current window |
| `Esc Esc` *(terminal)* | Back to normal mode (a single `Esc` still reaches the program) |
| `z <part of a path>` | Jump to a folder you use often (`z -l <part>` lists the matches) |
| `testfile Button.test.tsx` | Run that test file with coverage for its source file; without a name it uses the clipboard |
| `copilot-auto` | Copilot CLI, on the local model when available |
| `exec zsh` | Reload the shell config |

Node switches on its own: entering a folder with an `.nvmrc` or `.node-version` uses that version, installing it if needed. Everywhere else it's the latest LTS.

### Keep it up to date

| Command | Does |
| --- | --- |
| `./setup.sh` | Update everything: Homebrew tools, Node LTS, Neovim plugins (to the lockfile), parsers, language servers |
| `:lua vim.pack.update()` | Update Neovim's plugins: review, then `:w` to apply or `:q` to cancel. Commit `nvim/nvim-pack-lock.json` afterwards; `./setup.sh` gives other Macs the same versions |
| `:Mason` | Language servers and tools: `i` install, `u` update, `U` update all, `X` uninstall, `g?` help |
| `:TSUpdate` | Update the Treesitter parsers |
| `:checkhealth` | Find setup problems (`:checkhealth vim.lsp` for language servers) |
| `:AIStatus` | Which AI backends are active, and how to fix missing ones |
| `:restart` | Restart Neovim, keeping the open files |

In the plugin update window, `]]` / `[[` move between plugins, `K` shows what changed and `gra` updates or skips the plugin under the cursor.

CI ([.github/workflows/ci.yml](.github/workflows/ci.yml)) checks the shell scripts and the Lua formatting, and installs this Neovim config from scratch on macOS.

## Key index

Every key this config adds. Neovim's own keys and the keys inside plugin windows are in the workflows above.

| Keys | Does | Workflow |
| --- | --- | --- |
| `,aa` | Agent CLI in a split, local model first | [AI](#ai) |
| `,ac` | AI chat; *visual*: add the selection to the chat | [AI](#ai) |
| `,af` | Send the file to the agent | [AI](#ai) |
| `,ag` | Agent CLI on GitHub's models | [AI](#ai) |
| `,al` | Ghost text from Copilot or the local model | [AI](#ai) |
| `,an` | Next edit suggestions on/off | [AI](#ai) |
| `,ap` | Agent prompts (also *visual*) | [AI](#ai) |
| `,as` | Choose the agent CLI | [AI](#ai) |
| `,at` | Send this spot or the selection to the agent (also *visual*) | [AI](#ai) |
| `,av` | *Visual*: send the selection to the agent | [AI](#ai) |
| `,bh` | Close the window, keep the file open | [Move around](#move-around) |
| `,bk` | Close the file, keep the window | [Move around](#move-around) |
| `,ca` | Code action (also *visual*) | [Code](#understand-and-change-code) |
| `,cd` | Go to definition | [Code](#understand-and-change-code) |
| `,ch` | Definition in a horizontal split | [Code](#understand-and-change-code) |
| `,ci` | Inlay hints on/off | [Code](#understand-and-change-code) |
| `,cr` | References | [Code](#understand-and-change-code) |
| `,cs` | Symbols in the file | [Code](#understand-and-change-code) |
| `,ct` | Type definition | [Code](#understand-and-change-code) |
| `,cv` | Definition in a vertical split | [Code](#understand-and-change-code) |
| `,db` | Breakpoint on/off | [Debug](#debug) |
| `,dB` | Conditional breakpoint | [Debug](#debug) |
| `,dc` | Continue | [Debug](#debug) |
| `,dC` | Clear all breakpoints | [Debug](#debug) |
| `,de` | End all debugging, clear breakpoints | [Debug](#debug) |
| `,di` | Step into | [Debug](#debug) |
| `,dl` | Value under the cursor | [Debug](#debug) |
| `,dn` | Step over | [Debug](#debug) |
| `,do` | Step out | [Debug](#debug) |
| `,dr` | Run the last configuration again | [Debug](#debug) |
| `,ds` | Start debugging, or continue | [Debug](#debug) |
| `,dv` | Debug view on/off | [Debug](#debug) |
| `,ed` | Full message for the problem under the cursor | [Code](#understand-and-change-code) |
| `,en` | Next problem, with its message | [Code](#understand-and-change-code) |
| `,ep` | Previous problem, with its message | [Code](#understand-and-change-code) |
| `,fb` | Buffers | [Find](#find-files-and-text) |
| `,ff` | Files | [Find](#find-files-and-text) |
| `,fg` | Search text | [Find](#find-files-and-text) |
| `,fh` | Neovim help | [Find](#find-files-and-text) |
| `,fn` | Copy the file's name | [Find](#find-files-and-text) |
| `,fr` | Resume the last picker | [Find](#find-files-and-text) |
| `,gb` | Blame the line | [Git](#git) |
| `,gd` | Diff against the index | [Git](#git) |
| `,gf` | Open changed files side by side | [Git](#git) |
| `,gp` | Preview the change | [Git](#git) |
| `,gr` | Reset the change | [Git](#git) |
| `,gs` | Stage the change | [Git](#git) |
| `,ma` | Run the whole test file | [Tests](#run-tests) |
| `,md` | Debug the test under the cursor | [Tests](#run-tests) |
| `,mi` | Playwright Inspector for the test under the cursor | [Tests](#run-tests) |
| `,ml` | Run the last tests again | [Tests](#run-tests) |
| `,mo` | Output of the test under the cursor | [Tests](#run-tests) |
| `,mO` | Output panel | [Tests](#run-tests) |
| `,mr` | Run the test under the cursor | [Tests](#run-tests) |
| `,ms` | Test summary | [Tests](#run-tests) |
| `,mu` | Playwright UI mode | [Tests](#run-tests) |
| `,mw` | Watch the file | [Tests](#run-tests) |
| `,mx` | Stop tests | [Tests](#run-tests) |
| `,sh` | Split horizontally | [Move around](#move-around) |
| `,ss` | Browse snippets | [Snippets](#snippets) |
| `,sv` | Split vertically | [Move around](#move-around) |
| `,tc` | New tab | [Move around](#move-around) |
| `,tm` | Terminal | [Shell](#terminal-and-shell) |
| `,tn` | Next tab | [Move around](#move-around) |
| `,tp` | Previous tab | [Move around](#move-around) |
| `,tt` | File tree on/off | [Move around](#move-around) |
| `,h` `,j` `,k` `,l` | Window left / below / above / right | [Move around](#move-around) |
| `,n` | Show the current file in the tree | [Move around](#move-around) |
| `,r` | Refresh the tree | [Move around](#move-around) |
| `Space` | Command line | [Reading the keys](#reading-the-keys) |
| `jj` | *Insert*: back to normal mode | [Reading the keys](#reading-the-keys) |
| `n` / `N` | Next / previous search match, centred | [Move around](#move-around) |
| `s` | Jump (also *visual* and after an operator) | [Move around](#move-around) |
| `S` | Select a syntax node (also *visual* and after an operator) | [Move around](#move-around) |
| `gd` | Go to definition | [Code](#understand-and-change-code) |
| `]h` / `[h` | Next / previous git change | [Git](#git) |
| `Tab` | Next edit suggestion, else forward through places you've been | [AI](#ai) |
| `<M-]>` / `<M-[>` | *Insert*: next / previous ghost text suggestion | [AI](#ai) |
| `F5` | Remove trailing whitespace | [Write](#write-code) |
| `Esc Esc` | *Terminal*: back to normal mode | [Shell](#terminal-and-shell) |

## Where things live

| Path | What |
| --- | --- |
| [setup.sh](setup.sh), [Brewfile](Brewfile) | Install and update |
| [script/nvim-sync.lua](script/nvim-sync.lua) | The Neovim part of setup: plugins to the lockfile, parsers, language servers |
| [zshrc](zshrc), [config/starship.toml](config/starship.toml) | Shell and prompt |
| [z.sh](z.sh) | `z` folder jumping ([rupa/z](https://github.com/rupa/z), vendored) |
| [bin/copilot-auto](bin/copilot-auto) | Copilot CLI, local model first |
| [nvim/init.lua](nvim/init.lua) | Loads [nvim/lua/config/](nvim/lua/config) (options, keys, autosave, statusline), then one file per area in [nvim/lua/plugins/](nvim/lua/plugins) |
| [nvim/lua/config/keymaps.lua](nvim/lua/config/keymaps.lua) | Keys that don't belong to a plugin |
| [nvim/lua/config/debug.lua](nvim/lua/config/debug.lua) | Debug configurations |
| [nvim/lua/config/mason.lua](nvim/lua/config/mason.lua) | Language servers and tools to install |
| [nvim/snippets/](nvim/snippets) | Snippets per file type; `react-hooks.lua` holds the hooks that .tsx and React .ts files share. Helpers (names from the file, React version) are in [nvim/lua/config/snippets.lua](nvim/lua/config/snippets.lua) |
| [nvim/nvim-pack-lock.json](nvim/nvim-pack-lock.json) | Plugin versions; commit it after updating plugins |
