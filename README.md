# dotfiles

My Mac setup for frontend work: zsh and iTerm2, plus Neovim 0.12 set up for TypeScript, React, Next.js, Vite and Electron, with tests, debugging and AI built in. One script sets up a new Mac or brings an existing one up to date.

This README explains every feature and key, area by area. To learn them while you work, [workflows.md](workflows.md) walks through everyday tasks step by step: building a component, fixing a failing test, reviewing a pull request and more.

**Contents:** [Set up a Mac](#set-up-a-mac) · [Reading the keys](#reading-the-keys) · [Words used here](#words-used-here) · [Cheat sheet](#cheat-sheet) · Workflows: [Find](#find-files-and-text) · [Move around](#move-around) · [Code](#understand-and-change-code) · [Write](#write-code) · [Snippets](#snippets) · [Save](#save-and-format) · [Git](#git) · [Tests](#run-tests) · [Scripts](#run-scripts) · [Debug](#debug) · [AI](#ai) · [Shell](#terminal-and-shell) · [iTerm2](#iterm2) · [Updates](#keep-it-up-to-date) · [Key index](#key-index) · [Where things live](#where-things-live)

## Set up a Mac

```sh
git clone https://github.com/BAJ-/dotfiles.git ~/projects/dotfiles   # any folder works
cd ~/projects/dotfiles
./setup.sh --dry-run   # lists what would change
./setup.sh
```

`setup.sh` works on a new Mac and on one that's already set up. It checks each step before doing anything, so running it again only changes what's missing or out of date. When nothing is, it says "Everything is up to date". With `--dry-run` it only lists what it would change.

What it does:

- Installs Homebrew if it's missing, then everything listed in the [Brewfile](Brewfile): Neovim, tree-sitter-cli, ripgrep, ast-grep, fd, fzf, fnm, Go, gh, starship, tig, shellcheck and the Hack Nerd Font. Anything that's installed but outdated is upgraded.
- Links `~/.zshrc`, `~/z.sh`, `~/.config/starship.toml` and `~/.config/nvim` to the files in this repo. If you already have your own versions of those files, they're moved to `~/.dotfiles-backup/<date-time>/` first, so nothing is lost.
- Installs the latest Node LTS with fnm and makes it the default.
- Removes the tools the old setup used: nvm, gvm, Rye, vim-plug and old Neovim data. Global npm packages and npm settings move over to the new Node first; the settings go to `~/.npmrc`.
- Installs Neovim's plugins at the versions recorded in [nvim/nvim-pack-lock.json](nvim/nvim-pack-lock.json), plus the Treesitter parsers (which Neovim uses for syntax highlighting) and the [language servers](#words-used-here).
- Sets up iTerm2: the Dotfiles and Hotkey profiles, ⌘-click to open files in Neovim, and the Frontend Workgroup, all explained in [iTerm2](#iterm2). It also installs iTerm2's shell integration and keeps it up to date.

At the end it lists what changed, and anything you still need to do yourself, such as signing in to Copilot (in Neovim: press `,al`, then run `:LspCopilotSignIn`) or making Dotfiles iTerm2's default profile.

Settings that belong on one Mac only, such as work proxies or tokens, go in `~/.zshrc.local`. `~/.zshrc` loads that file, but it isn't part of this repo, which is public, so copy it to a new Mac yourself.

## Reading the keys

- **The leader key is `,`.** Most keys this setup adds start with it. `,ff` means: press `,`, then `f`, then `f`, one after the other.
- **Ctrl, Shift and Option** are written the way Neovim writes them: `<C-v>` is Ctrl+V, `<S-Tab>` is Shift+Tab and `<M-]>` is Option+]. Option keys only reach Neovim when iTerm2 sends them as **Esc+**, which the Dotfiles profile sets up for both Option keys.
- **iTerm2's own keys** use the Mac symbols: ⌘ Command, ⌥ Option, ⌃ Control, ⇧ Shift.
- **Modes:** keys work in normal mode unless they're marked *insert* (while you type text), *visual* (while text is selected) or *terminal* (inside a terminal in Neovim).
- **Forgot a key?** Press `,` and wait a moment: a popup lists every key that can follow, with what it does. The same works after `g`, `z`, `[`, `]`, `<C-w>`, `"` and `'`. Inside plugin windows, `g?` (file tree, debug view, Mason), `?` (test summary, AI chat) or `F1` (pickers) lists that window's keys.

## Words used here

- **Buffer:** a file that's open in Neovim. Closing the window that shows it doesn't close the file: it stays open in the background, ready to show again.
- **Window and split:** a window is an area of the screen that shows a buffer. Splitting puts two windows side by side (a vertical split) or one above the other (a horizontal split).
- **Tab:** a separate screen with its own windows, like a tab in a browser.
- **Picker:** a pop-up list you search by typing, used to find files, search text, pick an open file and more. Type a few letters to narrow the list, move with `<C-n>` / `<C-p>` or the arrow keys, and press `Enter` to open the selected entry.
- **Quickfix list:** a list of places in your code (file and line) that a command collected for you to go through, such as search results, the places a function is used, or type errors. `]q` goes to the next place and `[q` to the previous one. A **location list** is the same thing, but belongs to one window.
- **Language server:** a program running in the background that understands the code in one language. It's what makes go to definition, rename, completion and the problems in your code work.
- **Problems:** errors and warnings shown in your code, from the language server, ESLint or failing tests. Each one has a sign in the left margin and its message at the end of the line. Neovim calls them diagnostics.
- **Code action:** a fix or change the language server offers for the code under the cursor, like adding a missing import.
- **Label:** a highlighted letter that the jump keys `s` and `S` put on every place you can jump to. Pressing that letter takes you there.
- **Operator:** a Vim key that acts on the stretch of text you pick with the keys that follow it. `d` deletes, `c` changes (deletes, then lets you type) and `y` copies. `dw` deletes a word, and `d` followed by a jump with `s` deletes everything up to where you jump.
- **Ghost text:** an AI suggestion shown in grey where you're typing; `Tab` accepts it. It's off until you turn it on.

## Cheat sheet

The keys you'll use most. Each one is explained in more detail in its section further down.

| Keys | Does |
| --- | --- |
| `,ff` | Find a file by name |
| `,fg` | Search the text of all files. `useState -- *.tsx` searches only .tsx files |
| `,fs` | Search and replace across files |
| `,fr` | Reopen the last picker, such as your last text search, as you left it |
| `,tt` | Open or close the file tree |
| `,n` | Show the current file in the file tree |
| `s` | Jump anywhere on screen: type one or two letters of the spot, then press the label that appears there |
| `gd` | Go to the definition of the name under the cursor |
| `K` | Show the type and docs of the name under the cursor |
| `,cr` | List every place the name under the cursor is used |
| `grn` | Rename the name under the cursor, in every file |
| `,ca` | Show code actions: quick fixes, add a missing import and more |
| `]d` / `[d` | Go to the next / previous problem |
| `Tab` *(insert)* | In the completion menu: select the next item. Otherwise: accept the AI's ghost text (if it's on), or go to the next field of a snippet |
| `gcc` | Comment or uncomment the line. `gc` does the same for selected lines |
| `,mr` / `,ma` | Run the test under the cursor / every test in the file |
| `,mt` | Open the test list: check off tests from any file and run them |
| `,pp` | Run a `package.json` script in its own iTerm2 pane, below Neovim |
| `,db`, then `,ds` | Set a breakpoint on the line, then start debugging |
| `]h` | Go to the next change you haven't committed yet |
| `,gp` / `,gs` | Preview that change / stage it |
| `,gf` | Open the files you've changed, side by side |
| `,gv` | Review everything your branch changes, one file at a time |
| `,aa` / `,ac` | Open the AI agent beside your code / open an AI chat |
| `,al` / `,an` | Turn AI ghost text / next edit suggestions on or off (both start off) |
| `Space` | Open the command line, the same as `:` |
| `jj` *(insert)* | Go back to normal mode |
| ⌘-click `src/App.tsx:42` *(iTerm2)* | Open that file in Neovim at that line |
| ⌃⌘W, then ⌃⌘1–4 *(iTerm2)* | Start the Frontend Workgroup, then show the dev server, tests, git or a shell beside your code |
| Double-tap ⌃ *(iTerm2)* | Show or hide a terminal that drops down from the top of the screen |

## Workflows

### Find files and text

`,ff` finds files by name and `,fg` searches the text inside them. Both open a [picker](#words-used-here): type to narrow the list, then press `Enter` to open the selected entry.

To search only some files with `,fg`, type ` -- ` after your search, then file patterns. `useState -- *.tsx` searches only .tsx files, and `useState -- *.tsx !*.test.*` also leaves out test files (`!` means "not").

| Keys | Does |
| --- | --- |
| `,ff` | Find a file by name. Hidden and git-ignored files are left out: in the picker, `<M-h>` adds hidden files and `<M-i>` git-ignored ones |
| `,fg` | Search the text of all files. See above for searching only some of them |
| `,fb` | Pick one of the files you have open (your buffers) |
| `,fh` | Search Neovim's help |
| `,fr` | Reopen the last picker as you left it, with the same search and selection |
| `,fs` | Search and replace across files (see below) |
| `,fn` | Copy the current file's name, like `UserCard.tsx`, to the clipboard |
| `,gf` | Pick from the files you've changed in git (see [Git](#git)) |

**Inside a picker:**

| Keys | Does |
| --- | --- |
| `Enter` | Open the selected entry. If you've marked several, they go to the [quickfix list](#words-used-here) instead |
| `<C-v>` / `<C-s>` / `<C-t>` | Open the entry in a vertical split / a horizontal split / a new tab |
| `Tab` / `<S-Tab>` | Mark the entry and move down / up, to open or collect several at once |
| `<M-a>` | Mark every entry |
| `<M-q>` | Send the marked entries to the quickfix list. `<M-Q>` sends them to the location list |
| `<M-h>` / `<M-i>` / `<M-f>` | Include hidden files / include git-ignored files / follow symbolic links |
| `<C-f>` / `<C-b>` | Move half a page down / up in the list |
| `<S-Down>` / `<S-Up>` | Scroll the preview |
| `F4` | Show or hide the preview |
| `F2` | Make the picker fill the screen |
| `F1` | List every picker key |
| `Esc` | Close the picker. `<M-Esc>` only hides it, and `,fr` brings it back |

**Search and replace across files.** Put the cursor on a word, or select some text, and press `,fs`. A search-and-replace window opens with that text in its search field. Type the replacement and, if you like, which files to change, such as `*.tsx` or `src/**`. Every match is listed with the replacement applied, so you can check them all before anything changes on disk.

| Keys *(in the search-and-replace window)* | Does |
| --- | --- |
| `Tab` / `<S-Tab>` | Go to the next / previous field: search, replace, files and the others |
| `\r` | Replace every match |
| `\j` | Replace only the next match |
| `Enter` | Open the file at the match under the cursor |
| `Down` / `Up` | Show the next / previous match in its file, as a preview |
| `\s` | If you've edited some of the listed lines by hand, save those edits to their files |
| `\e` | Switch to ast-grep, which matches the structure of code instead of its text. `$A * 2` finds every multiplication by 2, and `console.log($$$)` every `console.log` call, whatever its arguments |
| `\q` | Put the matches in the quickfix list, to change them yourself one by one |
| `\c` | Close the window |
| `g?` | List every key in this window |

### Move around

**File tree.** `,tt` opens and closes the file tree on the left. `,n` opens it with the current file selected, and `,r` refreshes it after files change outside Neovim. Renaming or moving a file in the tree updates every import that points to it. Starting Neovim on a folder, as in `nvim .`, opens the tree right away.

| Keys *(in the tree)* | Does |
| --- | --- |
| `Enter` or `o` | Open the file, or open or close the folder |
| `<C-v>` / `<C-x>` / `<C-t>` | Open the file in a vertical split / a horizontal split / a new tab |
| `Tab` | Preview the file without leaving the tree |
| `a` | Create a file. End the name with `/` to create a folder instead |
| `r` | Rename the file or folder. `e` edits only the name and keeps the extension, `u` edits the whole path |
| `d` | Delete the file or folder |
| `x` / `c` / `p` | Cut / copy / paste. Paste on a folder to move or copy into it |
| `y` / `Y` / `gy` | Copy the file's name / its path from the project's folder / its full path |
| `H` / `I` | Show or hide dotfiles / git-ignored files |
| `f` / `F` | Show only the files whose name matches what you type / show all files again |
| `W` / `E` | Close / open every folder |
| `P` | Go to the folder the cursor is in |
| `-` / `<C-]>` | Move the top of the tree up one folder / make the folder under the cursor the top of the tree |
| `]c` / `[c` | Go to the next / previous file with git changes |
| `]e` / `[e` | Go to the next / previous file with problems |
| `q` | Close the tree |
| `g?` | List every tree key |

**Jumping**

| Keys | Does |
| --- | --- |
| `s` | Jump to any spot you can see. Press `s` and type the first one or two letters of that spot. A [label](#words-used-here) appears next to every match: press the one at your spot and the cursor jumps there |
| `d` then `s` | Delete everything from the cursor up to a spot you pick with `s`. It works the same with the other [operators](#words-used-here): `y` then `s` copies up to that spot, and `c` then `s` changes it |
| `S` | Select a whole piece of code: a JSX element, a function argument, a function. Press `S`, and labels appear around the pieces the cursor is in: press one to select that piece. `d` then `S` deletes the piece you pick instead |
| `f` + a character | Jump to the next place that character appears, also on later lines. Press `f` again for the one after it, or `F` to go back. `;` also goes to the next one |
| `t` + a character | The same as `f`, but stops just before the character |
| `F` / `T` + a character | The same as `f` / `t`, searching backwards |
| `<C-o>` / `Tab` | Go back / forward through the places you've jumped to, like a browser's back and forward buttons. With next edit suggestions on, `Tab` first jumps to the suggested edit, if there is one ([AI](#ai)) |
| `%` | Jump to the matching bracket, or to the matching opening or closing JSX or HTML tag |
| `gx` | Open the link or file under the cursor in its app, such as a web address in your browser |
| `n` / `N` | Go to the next / previous match of your last search (`/`), centred on the screen |

In plain Vim, `,` repeats `f` backwards. Here `,` is the leader key, so press `F` instead. `s` and `S` also replace two Vim keys: `s` used to delete a character and start typing, which `cl` still does, and `S` used to replace the whole line, which `cc` still does.

**Windows, buffers and tabs**

| Keys | Does |
| --- | --- |
| `,h` `,j` `,k` `,l` | Go to the window on the left / below / above / on the right |
| `,sv` / `,sh` | Split the window vertically, side by side / horizontally, one above the other |
| `,bh` | Close the window. The file stays open in the background |
| `,bk` | Close the file, but keep the window and show another file in it. It asks first if the file has unsaved changes |
| `[b` / `]b` | Show the previous / next open file in this window |
| `,tc` / `,tn` / `,tp` | Open a new tab / go to the next tab / go to the previous tab |
| `<C-w>` | Press and wait: a popup lists every window command, such as resizing, swapping and maximising windows |

**Lists of places.** Several features collect places in your code for you to go through one by one: the search results you send from a picker with `<M-q>`, every place a name is used (`grr`), the type errors from `,et`, and more. They go in the [quickfix list](#words-used-here).

| Keys | Does |
| --- | --- |
| `]q` / `[q` | Go to the next / previous place in the quickfix list |
| `]Q` / `[Q` | Go to the last / first place in it |
| `]l` / `[l` | The same for the location list, such as the outline that `gO` makes |

### Understand and change code

[Language servers](#words-used-here) start on their own for TypeScript and JavaScript, ESLint, CSS and SCSS, CSS Modules, CSS variables, HTML, JSON, YAML, Markdown, GitHub Actions workflows, Lua and Bash. For TypeScript, projects on TypeScript 7 or later use TypeScript's own language server (`tsc --lsp`), and older projects use vtsls. If a language server gets stuck, `:lsp restart` restarts it.

Some kinds of files get extra help:

- **CSS Modules:** after `styles.`, the class names from the module complete, and `gd` on `styles.card` jumps to the `.card` rule.
- **JSON and YAML** files are checked against their published schemas. A wrong value in package.json, tsconfig.json, devcontainer.json, an ESLint or Prettier config and many more shows as a problem, and valid keys and values complete as you type.
- **GitHub Actions workflows** (the files in `.github/workflows/`) are checked by GitHub's own Actions language server. It checks the `${{ }}` expressions and every action's inputs, which it reads from GitHub using your `gh` login.
- **Markdown:** links to headings and files complete as you type, and a link to a file that doesn't exist shows as a problem. `gd` follows a link, and `grn` on a heading renames it along with every link to it.

| Keys | Does |
| --- | --- |
| `gd` (or `,cd`) | Go to the definition of the name under the cursor |
| `,cv` / `,ch` | Open the definition in a vertical / horizontal split, next to the code you're reading |
| `,ct` (or `grt`) | Go to the definition of its type |
| `gri` | List the implementations of an interface or an abstract method |
| `,cr` | List every place the name is used, in a picker with a preview. `grr` puts them in the quickfix list instead |
| `,cs` | List the components, functions, types and other names defined in this file, in a picker. `gO` puts them in the location list as an outline instead |
| `K` | Show the type and docs of what's under the cursor. Press `K` again to move into that window, to scroll or copy |
| `<C-s>` *(insert)* | While you type a function call, show the function's parameters |
| `,ca` (or `gra`) | Show the [code actions](#words-used-here) for the cursor, or for the selected lines: quick fixes, adding the missing import and more |
| `grn` | Rename the name under the cursor, in every file that uses it |
| `grx` | Run the code lens on this line. A code lens is an action some language servers show above a line of code, such as "Run test" |
| `,ci` | Show or hide inlay hints: parameter names and inferred types, shown in grey inside your code |
| `,cx` | Turn sticky context on or off. It's on from the start: as you scroll, the component, function or `describe` / `it` block you're in stays at the top of the window |

**Problems**

| Keys | Does |
| --- | --- |
| `]d` / `[d` | Go to the next / previous [problem](#words-used-here) |
| `]D` / `[D` | Go to the last / first problem in the file |
| `,en` / `,ep` | Go to the next / previous problem, show its message and centre it on the screen |
| `,ed` (or `<C-w>d`) | Show the whole message of the problem under the cursor, for long ones like TypeScript's |
| `,et` (or `:TypeCheck`) | Type-check the whole project, not just the files you have open. The project's own `tsc` runs in the background, and the status line shows **TypeCheck:** and the project's folder while it runs. The errors go to the quickfix list, where `]q` and `[q` take you from one to the next |

Failing tests show up as problems too, on the line that failed.

### Write code

The completion menu appears as you type. It suggests names from the language server, file paths, [snippets](#snippets) and words already in the file. There's no AI in it: AI suggestions are separate, and stay off until you turn them on ([AI](#ai)).

In HTML, and between tags in JSX and TSX, the menu also offers Emmet abbreviations, which expand into markup. `ul>li*3` gives a list with three items, and `div.card>p*2` a `div` with `className="card"` and two paragraphs inside. In code and inside `{…}` it doesn't offer them, so `user.n` still completes to `user.name`.

| Keys *(insert)* | Does |
| --- | --- |
| `Tab` | With the menu open: select the next item. Otherwise it does the first of these that applies: accept the AI's ghost text if it's on, go to the next field of a snippet, or insert a tab |
| `<S-Tab>` | Select the previous item, or go to the previous field of a snippet |
| `<C-n>` / `<C-p>` (or `Down` / `Up`) | Select the next / previous item |
| `Enter` | Accept the selected item. With nothing selected, it starts a new line |
| `<C-e>` | Close the menu |
| `<C-Space>` | Open the menu. Press it again to show or hide the documentation of the selected item |
| `<C-f>` / `<C-b>` | Scroll that documentation |
| `<C-k>` | Show or hide the parameters of the function you're calling |

**Snippets.** Type a snippet's trigger and pick it in the menu. Every snippet, and how to use them, is in [Snippets](#snippets).

**Editing**

| Keys | Does |
| --- | --- |
| `gcc` | Comment or uncomment the line. In JSX it uses `{/* */}` |
| `gc` + a motion | Comment several lines: `gcip` comments the paragraph. In visual mode, `gc` comments the selected lines |
| `dgc` | Delete the comment block under the cursor |
| `S` | Select a piece of code by its structure (see Jumping in [Move around](#move-around)) |
| `an` / `in` *(visual)* | Grow the selection to the piece of code around it / shrink it to the piece inside |
| `]n` / `[n` *(visual)* | Select the next / previous piece of code. `]N` / `[N` select the next / previous one at the same level |
| `]<Space>` / `[<Space>` | Add an empty line below / above the cursor |
| `F5` | Remove the trailing whitespace in the whole file |
| `>` *(insert)* | Close a JSX or HTML tag for you: typing the `>` of `<div>` adds `</div>` after the cursor. Renaming an opening tag renames its closing tag too |

### Snippets

A snippet writes a common piece of code for you. Type its trigger, like `rafc`, select it in the completion menu with `Tab` and press `Enter`. The code appears with placeholders, called fields, for the parts you fill in. The first field is selected, so typing replaces it.

- `Tab` / `<S-Tab>` go to the next / previous field. If the completion menu opened while you typed in a field, close it with `<C-e>` first, or `Tab` selects an item in the menu instead.
- Some names follow a field as you type it: in `us`, typing `count` also writes `setCount`, and in `jmap` the closing tag follows the element you type.
- Moving the cursor out of a snippet ends it, so a later `Tab` doesn't jump back into it.
- Snippets don't add imports. Put the cursor on the name that needs one and press `,ca`.
- `,ss` lists every snippet for the current file type, with the file it comes from.

**JavaScript and TypeScript files**

| Trigger | Writes | Fields, in order |
| --- | --- | --- |
| `cl` | `console.log(…)` | value |
| `tc` | `try { … } catch (error) { console.error(error) }` | the code to try, what to do with the error |
| `ed` | `export default …` | value |
| `af` | `async function name(…) { … }` | name, parameters, body |
| `arf` | `const name = (…) => { … }` | name, parameters, body |
| `tne` | ``throw new Error(`message`)`` | message |
| `pa` | `const [a, b] = await Promise.all([…])` | names, promises |
| `fetchj` | Fetches a URL, throws an error unless the response is OK, then reads the JSON | URL, name for the data |

`af` and `arf` leave out the return type, so TypeScript works it out from the code.

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
| `guard` | `function isUser(value: unknown): value is User { return … }`, a function that tells TypeScript what type a value has | the type (written in both places), the check |

**React hooks** work in .tsx files, and in .ts files that import from `'react'` or whose name starts with `use`, like `useWindowSize.ts` or `use-window-size.ts`.

| Trigger | Writes | Fields, in order |
| --- | --- | --- |
| `us` | `const [count, setCount] = useState(…)` | name (the setter's name follows it), start value |
| `ust` | `const [user, setUser] = useState<User \| null>(…)` | name, type, start value |
| `ue` | `useEffect(() => { … }, [])` | body, dependencies |
| `uel` | An effect that adds an event listener, and removes it again when the component goes away | event (the handler's name and the event's type follow it), target, the handler's body, dependencies |
| `ucb` | `const fn = useCallback((…) => { … }, [])` | name, parameters, body, dependencies |
| `um` | `const value = useMemo(() => { return … }, [])` | name, value, dependencies |
| `ur` | `const ref = useRef<type>(null)` | name, type, start value |
| `hook` | `export const useWindowSize = (…) => { … }` | name (taken from the file's name, otherwise `useName`), parameters, body |

`uel` gives the handler's `event` the right type for the event you typed: `keydown` gives `KeyboardEvent`, `click` gives `MouseEvent`, and any event it doesn't know gives `Event`.

```tsx
// uel: type "resize", press Tab to keep "window", then write the handler
useEffect(() => {
  const handleResize = (event: Event) => {
    setWidth(window.innerWidth)
  }
  window.addEventListener('resize', handleResize)
  return () => window.removeEventListener('resize', handleResize)
}, [])
```

**React components** work in .tsx files.

| Trigger | Writes | Fields, in order |
| --- | --- | --- |
| `rafc` | An arrow-function component named after the file, with an interface for its props | the props interface, the props, the JSX |
| `rfc` | An `export default function` component named after the file, with an interface for its props | the props interface, the props, the JSX |
| `rfcc` | The same as `rfc`, with `"use client"` at the top, for a Next.js client component | the props interface, the props, the JSX |
| `jmap` | `{items.map((item) => (<li key={item.id}></li>))}` | the array, the item's name (its `key` follows), the element (its closing tag follows), the content |
| `ctx` | A context, a provider for it, and a hook that throws an error when it's used outside the provider | name (used in all three), the value's type, the value |

- `rafc` names the component after the file, in PascalCase: `user-card.tsx` gives `UserCard`. In an `index.tsx` it uses the folder's name. `rfc` and `rfcc` use the file's name as it is.
- `ctx` takes its name from the file, without `Context` or `Provider`: `ThemeContext.tsx` gives `Theme`. On React 19 and later it writes `<ThemeContext value={value}>`, and on older versions `<ThemeContext.Provider value={value}>`. It goes by the React version installed in the project, or the one in its package.json if nothing is installed yet.

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

**After an expression.** In JavaScript and TypeScript files, these triggers go right after an expression, and wrap it:

| Trigger | Turns | Into |
| --- | --- | --- |
| `.log` | `user.name.log` | `console.log(user.name)` |
| `.await` | `res.json().await` | `await res.json()` |
| `.return` | `getUser(id).return` | `return getUser(id)` |
| `.const` | `items.filter(isOpen).const` | `const name = items.filter(isOpen)`, with `name` selected so you can type the real name |
| `.if` | `user.isAdmin.if` | `if (user.isAdmin) { … }` |

- They wrap the whole expression before the dot, even a chain of calls over several lines: `a.b().c.log` logs `a.b().c`. Inside brackets they stop at the bracket: `fn(a.b.log)` logs `a.b`.
- `.log`, `.return`, `.const` and `.if` also wrap comparisons, `!x` and `await x`: `a > b.if` gives `if (a > b)`. `.await` only wraps the last part: `a + b.await` gives `a + await b`.
- The menu only offers them right after an expression and a dot, not in comments, strings or JSX text. You don't need to type the whole trigger: type `user.lo` and pick `.log`.

### Save and format

- **Autosave.** Files save themselves a second after you stop changing them in normal mode, and a second after you leave insert mode. They also save when you switch away from Neovim, to another app or another terminal pane. That way a dev server picks up your changes without you typing `:w`. Nothing is saved while you're still typing.
- **Formatting.** Saving formats the file with Prettier: JavaScript, TypeScript, CSS, SCSS, HTML, JSON, Markdown, YAML and GraphQL. When you save with `:w` yourself, ESLint's automatic fixes run first, such as removing unused imports. Autosave skips them, so an import you've just added isn't removed before you get to use it.
- `:Format` formats the file right away, and `:LspEslintFixAll` applies ESLint's fixes right away. Lua files are formatted with stylua, but only in projects that have a stylua config.
- **Changes from outside Neovim.** When git or an AI agent changes a file you have open, Neovim reloads it as soon as you go back to it.
- **Undo history** is kept when you close a file, so `u` still undoes your changes after you reopen it. `,u` shows the whole history as a tree: move through it and the file changes with you, so you can get back any earlier version. `,u` again closes it.

### Git

Lines you've changed since the last commit are marked in the left margin. Each block of changed lines is a change you can preview, stage or undo on its own.

| Keys | Does |
| --- | --- |
| `]h` / `[h` | Go to the next / previous change in the file |
| `,gp` | Preview the change under the cursor: the old lines next to the new ones |
| `,gs` | Stage the change, ready to commit. It's like `git add`, for just those lines |
| `,gr` | Undo the change, putting back the lines git has |
| `,gb` | Show who last changed the line and when, with the full commit message |
| `,gd` | Compare the file with the version git has, side by side. That's the staged version if you've staged something, otherwise the last commit |
| `,gf` | Pick from the files you've changed (`Tab` marks several), then press `Enter` to open them side by side: two next to each other, three as one above two, more in a grid |
| `,gv` (or `:Review [branch]`) | Review your branch one file at a time (see below). `,gv` again, or `:ReviewEnd`, closes the review |
| `,go` | Open the line, or the selected lines, on GitHub |
| `,gy` | Copy the GitHub link to the line, or the selected lines |
| `:DiffTool a b` | Compare two folders or two files |

**Reviewing a branch or a pull request.** `,gv` shows everything your branch changes, compared with the point where it split off the default branch (usually `origin/main`). It's like the "Files changed" tab of a pull request on GitHub. `:Review some-branch` compares with another branch instead. To review someone else's pull request, check it out first with `gh pr checkout 123`.

The review opens in a new tab, with the original version of a file on the left, your version on the right, and every changed file listed below.

- `]q` / `[q` go to the next / previous file, and `]c` / `[c` to the next / previous change in the file.
- The right side is the real file, so `gd`, `K`, references and the other language server keys work while you read.
- While the review is open, the change marks in the margin, `]h` and `,gp` compare against the same starting point, and the status line shows `REVIEW vs main`.

**GitHub links** from `,go` and `,gy` point at the exact commit when GitHub has it, so they keep showing the same lines later. When the commit isn't on GitHub yet, they point at the branch instead, and warn you that GitHub may show different lines.

The file tree marks changed files: ✗ changed, ✓ staged and ★ new. For anything else, like committing or browsing the history, use `tig` or `gh` in a terminal (`,tm`).

### Run tests

The same keys work for Vitest, Jest and Playwright tests. Each test runs with the test runner and config of the package it belongs to, which matters in a monorepo.

| Keys | Does |
| --- | --- |
| `,mr` | Run the test under the cursor |
| `,ma` | Run every test in the file |
| `,ml` | Run the last tests again, from any file. After a run from the test list (`,mt`), it runs those tests again |
| `,md` | Debug the test under the cursor. It stops at your breakpoints, so set them with `,db` first |
| `,mw` | Watch the file: its tests run again every time it's saved. Press `,mw` again, in the same file, to stop watching it. The test list (`,mt`) shows which files are watched, and stops them too |
| `,mx` | Stop every Vitest and Jest run in progress, wherever the cursor is |
| `,mo` | Show the output of the test under the cursor, including its `console.log`s |
| `,mO` | Open the output panel, with the output of every test run |
| `,ms` | Open the test summary: every test in the project, with its result |
| `,mt` | Open or close the test list: every Vitest, Jest and Playwright test in the project, to check off and run. It's explained below |

While Vitest or Jest tests run, the status line shows **Tests:** and the file's name. When they finish, the message line at the bottom of the screen says how it went: "✓ 12 tests passed in UserCard.test.tsx (1.2s)" in green, or "✗ 2 of 12 tests failed in UserCard.test.tsx (1.4s)" in red. `:messages` lists the earlier results.

A sign next to each test also shows whether it passed or failed. A failure shows as a [problem](#words-used-here) on the line that failed too, so `]d` takes you there.

Playwright tests (files that import `@playwright/test`) run in a terminal below your code instead, so you can follow along. Two more keys are just for them:

| Keys | Does |
| --- | --- |
| `,mu` | Open Playwright's UI mode: a separate window where you can run any test and watch it step by step |
| `,mi` | Run the test under the cursor in a browser you can see, paused before its first step. The Playwright Inspector, a separate window, controls it: press Resume or Step over there to continue |

If the browser just sits there after `,mi`, the Inspector is probably hidden behind the browser or behind iTerm2. Press F3 (Mission Control) to find it.

**In the test summary** (`,ms`):

| Keys | Does |
| --- | --- |
| `r` / `d` | Run / debug the test or file under the cursor |
| `o` / `O` | Show its output / a short version of the output |
| `i` | Go to the test in its file |
| `J` / `K` | Go to the next / previous failed test |
| `w` | Watch the test or file under the cursor: run it again on every save |
| `m` | Mark a test. Then `R` runs the marked tests, `D` debugs them and `M` clears the marks |
| `u` | Stop the tests that are running |
| `Enter` / `e` | Open or close the entry under the cursor / open every entry |
| `?` | List every summary key |

**The test list** (`,mt`) shows every test in the project in a panel on the right, so you can pick tests from different files and run them without opening the files. It has an area for each kind of test: one for Vitest or Jest, and one for each Playwright folder, named after the folder, like *Playwright (tests/e2e)*. Files stay closed until you open them, an area closes and opens with `Enter` on its title, and `/` filters the list as you type.

```
 Tests  ? shows the keys
 ▾ Jest                                452 files · 3 checked
 ▸ ☐ src/hooks/useAuth.test.ts                               ✓
 ▾ ◩ src/components/UserCard/UserCard.test.tsx     watching ✗
     ☑ renders the name                                      ✓
     ☐ shows an error when loading fails                     ✗

 ▸ Playwright (tests/e2e)                               36 files
```

| Keys | Does |
| --- | --- |
| `Space` | Check or uncheck the test under the cursor. On a file, it checks or unchecks every test in the file, and on an area's title, every test in the area. While the list is filtered, only the tests on show. To check several lines at once, select them with `V` first |
| `Enter` | Open or close the file or area under the cursor. On a test, go to it |
| `/` | Filter the list as you type, at the bottom of the screen: only the tests that match stay on show. `Enter` keeps the filter, and `Esc` removes it. Press `/` again to change it |
| `Esc` | Remove the filter |
| `r` | Run the checked tests. A file or describe block that's checked in full runs as one |
| `a` | Run every test in the area under the cursor. While the list is filtered, it runs only the ones on show |
| `i` | Go to the test or file under the cursor, in the window you opened the list from |
| `o` | Show the output of the Vitest or Jest test under the cursor |
| `w` | Watch the Vitest or Jest file or test under the cursor: it runs once straight away, then again every time you save it or the code it tests. Press `w` again to stop watching it |
| `c` | Uncheck everything |
| `?` | Show or hide these keys at the top of the list |
| `q` | Close the list. `,mt` opens and closes it too |

- **Filtering:** every word you type has to appear in a test's file path, its describe blocks or its name, in any order. `login error` shows the tests with *error* in their name, in files with *login* in their path. When the words match test names, their files open to show just those tests; when they match a file's path, the whole file stays on show. Lowercase words match either case, and a capital letter makes the filter match case exactly. The area titles count the files that match, like *3 of 452 files*, and the title bar at the top shows the filter.
- **A closed area** still counts its files, and shows ✗ when one of its tests failed, or … while some are running.
- **The marks:** ☑ is checked, and ◩ means some of the tests in that file or describe block are checked. At the right edge, ✓ means passed, ✗ failed, ○ skipped and … running, and *watching* marks a watched file or test. When you run some of a file's tests, Vitest and Jest report its other tests as skipped, so those show ○ until they run again.
- **Your checks stay** while Neovim is open, even after you close the list or change the filter. `r` in the list, or `,ml` from any file, runs the same tests again.
- **Vitest and Jest tests** run the same way as with `,ma`: the status line shows **Tests:** while they run, and the result shows in the message line and in the list. **Playwright tests** run in the terminal below your code, all the checked ones in a single run.
- **The Playwright area** comes from Playwright itself, so it lists exactly what Playwright would run. The first time, reading it takes a few seconds. After that, the list opens straight away and reads it again in the background, and again whenever you save a spec.
- **The status line** shows which kinds of tests the project has, like **󰙨 Jest · Playwright**, next to the mode.
- The test summary (`,ms`) is neotest's own view of the Vitest and Jest tests, with debugging and output for each test. The test list adds Playwright, check boxes, filtering and watched files.

### Run scripts

`,pp` lists every script in the project's `package.json` files, including packages in subfolders, such as `tests/e2e` or the packages of a monorepo, which show their folder. Type to narrow the list down; the preview beside it shows the script in its `package.json`. `Enter` runs it.

| Keys | Does |
| --- | --- |
| `,pp` | Pick a `package.json` script and run it in its own iTerm2 pane, below Neovim |
| `,pl` | Run the last script again |
| `,px` | Close the script panes below Neovim, stopping any script still running in them |
| ⇧⌘↩ *(iTerm2)* | Give Neovim the whole tab, hiding the script panes while they keep running. Press it again to bring them back |

- **Each script gets its own iTerm2 pane** at the bottom of the tab, below Neovim, named after the script and project, like *build · my-app*. The first one takes half of Neovim's height, and the next ones open beside it, so Neovim keeps its size. The script runs in its package's folder, with the package manager the project uses, such as `npm run build` or `pnpm run build`.
- **The cursor stays in Neovim.** ⌥⌘↓ takes you down into the pane and ⌥⌘↑ back up to Neovim; clicking works too. ⌘W closes the pane you're in, and `,px` closes them all from Neovim.
- **Out of the way for a while:** ⇧⌘↩ in Neovim gives it the whole tab. The script panes are hidden, but their scripts keep running, and ⇧⌘↩ again brings them back. It's iTerm2's View › Maximize Active Pane, so in the Workgroup it hides the dev server pane too, until you press it again.
- **The pane stays open** when the script ends, so you can read its output, or press ↑ and `Enter` there to run it again. The command is typed into the pane's shell, so your shell's setup loads first, as in any other pane, and ⌘-click and ⌥⌘A work there too.
- **One pane per script** in Neovim's tab: picking a script that's still running in its pane starts nothing, and Neovim tells you so. If it has finished, it runs again in the same pane. Each pane remembers which script it runs, so this also works after you restart Neovim. Close a script's pane, or all of them with `,px`, to start afresh: the next run opens a new one.
- The Frontend Workgroup's Dev server pane already runs the dev server, so picking `dev` while the Workgroup is open would start a second one.
- **It needs iTerm2.** When Neovim runs in another terminal, `,pp`, `,pl` and `,px` say so instead.

### Debug

1. Put the cursor on the line where the code should stop, and press `,db` to set a breakpoint there. `,dB` sets one that only stops when a condition is true, like `user.id === '42'`.
2. Press `,ds` and pick a configuration: what to run and how (see the table below). The debug view opens.
3. Use the app, or let the code run, until it stops at your breakpoint. Step through the code with `,dn` (to the next line), `,di` (into the function being called) and `,do` (out of the current function). `,dc` runs on to the next breakpoint, and `,dl` shows the value of what's under the cursor.
4. When you're done, `,de` ends everything, including any processes the program started, and removes the breakpoints. `,dr` runs the same configuration again.

| Configuration | Use it for |
| --- | --- |
| Node: current file | The JavaScript or TypeScript file you have open. Node runs TypeScript directly, without a build step |
| Vitest / Jest / Playwright: current file | The tests in the test file you have open. To debug only the test under the cursor, press `,md` instead |
| Next.js: server (dev script) | The server side of a Next.js app: route handlers and server components. It starts the project's dev script under the debugger, with npm, pnpm, yarn or bun, going by the lockfile |
| Next.js: client in Chrome (:3000) | Client components. Start the dev server first: this opens Chrome on port 3000, connected to the debugger |
| Vite: client in Chrome (:5173) | The same for a Vite app, on port 5173 |
| Electron: main + renderer | An Electron app: it starts the app and debugs both its main process and its window (the renderer). Electron Forge projects start through Forge |
| Electron: main process | Only the main process of an Electron app |
| Electron: renderer (attach :9222) | Only the window of an Electron app that's already running with debugging on port 9222 |
| Node: attach to :9229 (node/next --inspect) | A Node process you started with `--inspect`, which listens on port 9229 |
| Node: attach to a process | Any Node process that's already running, picked from a list |

If the project has a `.vscode/launch.json`, its configurations are offered too. In Electron Forge projects that use Vite, breakpoints in the main process only work with `build: { sourcemap: true }` in `vite.main.config.*`, and you get a warning when it's missing.

| Keys | Does |
| --- | --- |
| `,db` | Set or remove a breakpoint on the line |
| `,dB` | Set a breakpoint with a condition |
| `,ds` | Start debugging, or continue when it's paused |
| `,dc` | Continue to the next breakpoint |
| `,dn` / `,di` / `,do` | Step over the line / into the function being called / out of the current function |
| `,dl` | Show the value of what's under the cursor |
| `,dv` | Show or hide the debug view |
| `,dr` | Run the last configuration again |
| `,dC` | Remove every breakpoint |
| `,de` | End all debugging and remove the breakpoints |

**In the debug view**, these keys switch between its panels:

| Keys | Does |
| --- | --- |
| `S` | Scopes: the variables where the code stopped |
| `W` | Watches: expressions you want to keep an eye on |
| `B` | Breakpoints |
| `E` | Exceptions: choose whether to stop when one is thrown |
| `T` | Threads, and the calls that led to where the code stopped |
| `R` | REPL: run code where the program stopped |
| `]v` / `[v` | Go to the next / previous panel. `]V` / `[V` go to the last / first |

Inside the panels:

| Keys | Does |
| --- | --- |
| `Enter` | Expand a variable, jump to a call or breakpoint, or turn an exception filter on or off |
| `i` or `a` | Add a watch expression |
| `e` / `d` | Edit / delete the watch expression under the cursor |
| `s` / `c` | Change / copy the value under the cursor |
| `[[` | Go up to the entry that contains this one |
| `g?` | List every debug view key |

### AI

All AI is off until you start it. There are four kinds:

- **Ghost text:** suggestions shown in grey as you type. `,al` turns them on and off.
- **Next edit suggestions:** Copilot predicts the next change you'll make somewhere else in the file. `,an` turns them on and off.
- **Chat:** ask questions about your code in a chat window, opened with `,ac`.
- **Agent:** Copilot CLI running beside your code, where it can read your project and make changes for you. `,aa` opens it.

Copilot only runs while ghost text or next edit suggestions are on. Chat and the agent only run while they're open.

**Signing in to Copilot**, once per Mac: turn on ghost text with `,al`, then run `:LspCopilotSignIn` and follow the steps.

**Local models.** If Ollama is running on your Mac with the right models (see the end of this section), chat and the agent use your local model instead of Copilot. Ghost text keeps using Copilot unless you switch it with `,aL`. Nothing local is installed by default. `:AIStatus` shows which AI features are on, what they use, and how to fix anything that's missing.

**Ghost text**, once it's on:

| Keys | Does |
| --- | --- |
| `,al` | Turn ghost text on or off |
| `,aL` | Switch ghost text between Copilot and the local model |
| `Tab` *(insert)* | Accept the suggestion, when the completion menu is closed |
| `<M-]>` / `<M-[>` *(insert)* | Show the next / previous suggestion |
| `,an` | Turn next edit suggestions on or off |
| `Tab` *(normal)* | With next edit suggestions on: jump to the edit Copilot suggests. Press `Tab` again to make that edit |

**The agent** runs Copilot CLI in a split beside your code. `,aa` uses your local model when one is running, and GitHub's models otherwise.

| Keys | Does |
| --- | --- |
| `,aa` | Open or close the agent |
| `,ag` | Open or close the agent on GitHub's models, even when a local model is running |
| `,as` | Choose which agent tool to run |
| `,at` | Tell the agent about the cursor's position, or about the selected lines, so you can ask about them |
| `,af` | Send the current file to the agent |
| `,av` *(visual)* | Send the selected text to the agent |
| `,ap` | Pick a ready-made prompt: explain, fix, review, write tests, optimize, document and more |

In the agent's window:

| Keys | Does |
| --- | --- |
| `<C-q>` | Switch to normal mode, to scroll or copy. In normal mode, `<C-q>` hides the agent |
| `q` *(normal)* | Hide the agent. It keeps running in the background |
| `<C-z>` | Go back to your code, leaving the agent open |
| `<C-p>` | Insert a ready-made prompt, or context such as the current file |
| `<C-f>` / `<C-b>` | Pick a file / an open buffer to add to the conversation |
| `<C-h>` | Go to the window on the left |

**Chat.** `,ac` opens a chat window. It uses your local model if one is running, otherwise Copilot CLI, otherwise Copilot, and tells you which. If you select some code first, `,ac` adds it to the chat.

| Keys *(in the chat)* | Does |
| --- | --- |
| `Enter` | Send your message |
| `<C-s>` *(insert)* | Send your message while you're still typing |
| `q` | Stop the answer |
| `<C-c>` | Close the chat |
| `ga` | Change the model, or what runs it |
| `gr` | Write the last answer again |
| `gy` | Copy the last code block |
| `gx` | Clear the chat |
| `]]` / `[[` | Go to the next / previous message |
| `{` / `}` | Go to the previous / next chat |
| `?` | List every chat key |

When the chat proposes changes to a file, they show in that file as a diff, and these keys decide what happens:

| Keys | Does |
| --- | --- |
| `gv` | Show the proposed changes as a diff |
| `}` / `{` | Go to the next / previous proposed change |
| `g2` | Accept the change |
| `g3` | Reject the change |
| `g1` | Accept every change to this file from now on, without asking |
| `g4` | Cancel |

**Local models (optional).** To run chat, the agent and ghost text on your own Mac instead of Copilot:

1. `brew install ollama`, then start it with `ollama serve`.
2. `ollama pull qwen3-coder:30b` for chat and the agent.
3. `ollama pull qwen2.5-coder:7b` for ghost text, then switch ghost text to it with `,aL`.

To use other models, set `AI_LOCAL_MODEL` (chat and the agent) and `AI_LOCAL_FIM_MODEL` (ghost text) to their names. If Ollama runs on another machine, set `OLLAMA_HOST` to its address.

### Terminal and shell

| Keys or command | Does |
| --- | --- |
| `,tm` | Open a terminal in the current window |
| `Esc Esc` *(terminal)* | Go to normal mode, to scroll or copy. A single `Esc` still goes to the program running in the terminal |
| `z <part of a folder's name>` | Go to a folder you use often, such as `z dotfiles`. `z -l <part>` lists the folders that match |
| `testfile Button.test.tsx` | Run that Jest test file, with coverage for the file it tests. Without a name, it uses the name on the clipboard, which `,fn` copies in Neovim |
| `dev server` | Start the project's dev server (see [iTerm2](#iterm2)) |
| `dev test` | Run the project's tests, again on every change |
| `copilot-auto` | Start Copilot CLI, on your local model when one is running |
| `exec zsh` | Reload the shell's settings after you change them |

**Node switches versions on its own.** When you go into a folder with an `.nvmrc` or `.node-version` file, that version of Node is used, and installed first if needed. Everywhere else, you get the latest LTS.

### iTerm2

`setup.sh` adds an iTerm2 profile called **Dotfiles**; make it your default profile (Settings › Profiles, select Dotfiles, then Other Actions… › Set as Default). It sets the font, makes both Option keys work in Neovim (Esc+), lets Neovim use the mouse, and keeps an unlimited scrollback. Its colours follow macOS: Tokyo Night Storm when your Mac is in dark mode, and Kanagawa Lotus in light mode. Neovim switches its colours along with it, even while it's running.

| Keys | Does |
| --- | --- |
| ⌘-click a path | Open the file in Neovim at that line and column, like `src/App.tsx:42:7` in test output, a stack trace or `tsc` errors. If Neovim is open on that project, even in another tab, the file opens there and its pane comes to the front. Otherwise a new tab starts Neovim |
| ⌥-drag | Select text the terminal's way, even while Neovim or another program uses the mouse |
| Double-tap ⌃ | Show or hide the hotkey window: a terminal that drops down from the top of the screen, over any app and on any desktop. The first time, macOS asks you to give iTerm2 Accessibility access, which it needs to notice the double-tap |
| ⌃⌘W | Start the Frontend Workgroup (see below) |
| ⌃⌘X | Close the Frontend Workgroup |
| ⌃⌘1 – ⌃⌘4 | In the Workgroup: show the Dev server / Tests / Git / Shell pane |
| ⌥⌘← / ⌥⌘→ / ⌥⌘↑ / ⌥⌘↓ | Go to the pane on the left / right / above / below |

**The Frontend Workgroup** turns an iTerm2 tab into a workspace for one project. Go to the project's folder and press ⌃⌘W:

- Your own session stays on the left. Run `nvim .` there.
- The right-hand third of the tab holds four panes that take turns, one visible at a time: **Dev server** (runs `dev server`), **Tests** (runs `dev test`), **Git** (runs `tig`) and **Shell**. All four start right away.
- ⌃⌘1 to ⌃⌘4, or the pane names in the bar above the panes, bring one to the front and put the cursor in it. ⌥⌘← takes you back to Neovim.
- When the command in a pane stops, a shell takes its place, so you can start it again.
- `exit` in one of the four panes, or ⌃⌘X, closes the Workgroup. Your own session stays open.

To change the panes or their commands, go to iTerm2's Settings › Workgroups.

**`dev server` and `dev test`** work in any terminal, not just the Workgroup. `dev server` runs the project's `dev` script, or `start` if there's no `dev`, with the package manager the project uses: npm, pnpm, yarn or bun, going by its lockfile. `dev test` runs Vitest or Jest in watch mode, starting with the tests affected by your changes. In a monorepo, both work from inside a package.

**The tab's status.** A coloured dot and a word under the tab's title show how things are going:

| Where | What it shows |
| --- | --- |
| Dev server (Vite, Next.js) | *starting*, then *ready* or *error* |
| Tests in a terminal (Vitest, Jest) | *3 failing* or *tests pass* |
| Neovim (the `,m` test keys and `,et`) | *testing* or *type-checking* while they run, then the result. A failure stays until the next run; a pass disappears after 10 seconds |

A tab shows the status of the pane you're in. When that pane has none, it shows the most important status among the tab's other panes. ⌥⇧⌘C opens the Cockpit, a list of every session's status, including the panes hidden behind others in the Workgroup.

When tests or a type check in Neovim finish while you're in another app or pane, a macOS notification tells you the result.

React's *not wrapped in act(...)* warnings from test runs are collected in iTerm2's Toolbelt, under Captured Output. The first time one appears, iTerm2 offers to show it.

**Shell integration** lets iTerm2 know where each command and its output start, so you can jump between them. `./setup.sh` installs it and keeps it up to date.

| Keys | Does |
| --- | --- |
| ⇧⌘↑ / ⇧⌘↓ | Go to the previous / next command in the scrollback |
| ⇧⌘A | Select the last command's output, ready to copy |
| ⌥⌘A | Get a notification when the command that's running finishes |
| ⇧⌘; | List the commands you've run recently |
| ⌥⌘/ | List the folders you've been in recently |

In a terminal inside Neovim (`,tm`), `[[` / `]]` jump between commands the same way.

**More of iTerm2's own keys:**

| Keys | Does |
| --- | --- |
| ⇧⌘O | Open Quickly: find any session, tab or profile by name |
| ⌘F | Find text and highlight it |
| ⌥⇧⌘F | Filter: hide every line that doesn't match what you type |
| ⇧⌘C | Copy mode: select text with the keyboard, using Vim's keys |
| ⇧⌘H | Paste history: paste something you copied earlier |
| ⇧⌘. | Composer: write a long command in a small editor before running it |
| ⌥⌘B | Instant replay: step back through what the screen showed earlier |
| ⇧⌘T | Reopen the tab or pane you just closed |
| ⇧⌘↩ | Maximize the pane you're in, hiding the other panes of the tab while they keep running. Press it again to bring them back |

**Changing the profiles.** The profiles live in [config/iterm2/profiles.json](config/iterm2/profiles.json), and iTerm2 picks up your changes as soon as you save that file. Make changes there, not in iTerm2's Settings › Profiles, where they'd be lost. If iTerm2 offers **Mark as Rewritable** when you try, choose Cancel.

### Keep it up to date

| Command | Does |
| --- | --- |
| `./setup.sh` | Update everything: the Homebrew tools, Node LTS, Neovim's plugins (to the versions in the lockfile), the Treesitter parsers, the language servers and iTerm2's shell integration. Run it in the dotfiles folder |
| `:lua vim.pack.update()` | Update Neovim's plugins to their latest versions. A window lists what would change: `:w` applies the updates and `:q` cancels. Afterwards, commit `nvim/nvim-pack-lock.json`, so `./setup.sh` installs the same versions on your other Macs |
| `:Mason` | Manage the language servers and tools: `i` installs, `u` updates, `U` updates everything, `X` uninstalls and `g?` lists every key |
| `:TSUpdate` | Update the Treesitter parsers |
| `:checkhealth` | Check the setup for problems. `:checkhealth vim.lsp` checks only the language servers |
| `:AIStatus` | Show which AI features are on, what they use, and how to fix missing ones |
| `:restart` | Restart Neovim, keeping your files open |

In the plugin update window, `]]` / `[[` move between plugins, `K` shows what changed in the plugin under the cursor, and `gra` lets you update or skip just that plugin.

Every push and pull request on GitHub runs CI ([.github/workflows/ci.yml](.github/workflows/ci.yml)). It checks the shell scripts and the Lua formatting, and installs this Neovim config from scratch on a Mac.

## Key index

Every key this setup adds, with a link to the section that explains it. Neovim's own keys, and the keys inside plugin windows, are explained in those sections.

| Keys | Does | Section |
| --- | --- | --- |
| `,aa` | Open or close the AI agent beside your code | [AI](#ai) |
| `,ac` | Open an AI chat. On a selection, add the selected code to the chat | [AI](#ai) |
| `,af` | Send the current file to the agent | [AI](#ai) |
| `,ag` | Open or close the agent on GitHub's models | [AI](#ai) |
| `,al` | Turn ghost text on or off | [AI](#ai) |
| `,aL` | Switch ghost text between Copilot and the local model | [AI](#ai) |
| `,an` | Turn next edit suggestions on or off | [AI](#ai) |
| `,ap` | Pick a ready-made prompt for the agent (also *visual*) | [AI](#ai) |
| `,as` | Choose which agent tool to run | [AI](#ai) |
| `,at` | Tell the agent about the cursor's position or the selection (also *visual*) | [AI](#ai) |
| `,av` | *Visual*: send the selected text to the agent | [AI](#ai) |
| `,bh` | Close the window; the file stays open | [Move around](#move-around) |
| `,bk` | Close the file; the window stays | [Move around](#move-around) |
| `,ca` | Show code actions (also *visual*) | [Code](#understand-and-change-code) |
| `,cd` | Go to the definition | [Code](#understand-and-change-code) |
| `,ch` | Open the definition in a horizontal split | [Code](#understand-and-change-code) |
| `,ci` | Show or hide inlay hints | [Code](#understand-and-change-code) |
| `,cr` | List every place the name is used | [Code](#understand-and-change-code) |
| `,cs` | List the names defined in this file | [Code](#understand-and-change-code) |
| `,ct` | Go to the definition of the type | [Code](#understand-and-change-code) |
| `,cv` | Open the definition in a vertical split | [Code](#understand-and-change-code) |
| `,cx` | Turn sticky context on or off | [Code](#understand-and-change-code) |
| `,db` | Set or remove a breakpoint | [Debug](#debug) |
| `,dB` | Set a breakpoint with a condition | [Debug](#debug) |
| `,dc` | Continue to the next breakpoint | [Debug](#debug) |
| `,dC` | Remove every breakpoint | [Debug](#debug) |
| `,de` | End all debugging and remove the breakpoints | [Debug](#debug) |
| `,di` | Step into the function being called | [Debug](#debug) |
| `,dl` | Show the value of what's under the cursor | [Debug](#debug) |
| `,dn` | Step over the line | [Debug](#debug) |
| `,do` | Step out of the current function | [Debug](#debug) |
| `,dr` | Run the last debug configuration again | [Debug](#debug) |
| `,ds` | Start debugging, or continue when it's paused | [Debug](#debug) |
| `,dv` | Show or hide the debug view | [Debug](#debug) |
| `,ed` | Show the whole message of the problem under the cursor | [Code](#understand-and-change-code) |
| `,en` | Go to the next problem and show its message | [Code](#understand-and-change-code) |
| `,ep` | Go to the previous problem and show its message | [Code](#understand-and-change-code) |
| `,et` | Type-check the whole project | [Code](#understand-and-change-code) |
| `,fb` | Pick one of the files you have open | [Find](#find-files-and-text) |
| `,ff` | Find a file by name | [Find](#find-files-and-text) |
| `,fg` | Search the text of all files | [Find](#find-files-and-text) |
| `,fh` | Search Neovim's help | [Find](#find-files-and-text) |
| `,fn` | Copy the current file's name to the clipboard | [Find](#find-files-and-text) |
| `,fr` | Reopen the last picker as you left it | [Find](#find-files-and-text) |
| `,fs` | Search and replace across files (also *visual*) | [Find](#find-files-and-text) |
| `,gb` | Show who last changed the line, and why | [Git](#git) |
| `,gd` | Compare the file with the version git has, side by side | [Git](#git) |
| `,gf` | Open the files you've changed, side by side | [Git](#git) |
| `,go` | Open the line on GitHub (also *visual*) | [Git](#git) |
| `,gp` | Preview the change under the cursor | [Git](#git) |
| `,gr` | Undo the change under the cursor | [Git](#git) |
| `,gs` | Stage the change under the cursor | [Git](#git) |
| `,gv` | Start or end a review of your branch | [Git](#git) |
| `,gy` | Copy the line's GitHub link (also *visual*) | [Git](#git) |
| `,ma` | Run every test in the file | [Tests](#run-tests) |
| `,md` | Debug the test under the cursor | [Tests](#run-tests) |
| `,mi` | Run the test under the cursor in a visible browser, with the Playwright Inspector | [Tests](#run-tests) |
| `,ml` | Run the last tests again, including the test list's last run | [Tests](#run-tests) |
| `,mo` | Show the output of the test under the cursor | [Tests](#run-tests) |
| `,mO` | Open the output panel | [Tests](#run-tests) |
| `,mr` | Run the test under the cursor | [Tests](#run-tests) |
| `,ms` | Open the test summary | [Tests](#run-tests) |
| `,mt` | Open or close the test list, to check off tests and run them | [Tests](#run-tests) |
| `,mu` | Open Playwright's UI mode | [Tests](#run-tests) |
| `,mw` | Watch the file: run its tests on every save. Again, in the same file, or `w` in the test list, to stop | [Tests](#run-tests) |
| `,mx` | Stop every Vitest and Jest run in progress | [Tests](#run-tests) |
| `,pl` | Run the last `package.json` script again | [Scripts](#run-scripts) |
| `,pp` | Pick a `package.json` script and run it in its own iTerm2 pane, below Neovim | [Scripts](#run-scripts) |
| `,px` | Close the script panes below Neovim | [Scripts](#run-scripts) |
| `,sh` | Split the window horizontally | [Move around](#move-around) |
| `,ss` | Browse the snippets for this kind of file | [Snippets](#snippets) |
| `,sv` | Split the window vertically | [Move around](#move-around) |
| `,tc` | Open a new tab | [Move around](#move-around) |
| `,tm` | Open a terminal | [Shell](#terminal-and-shell) |
| `,tn` | Go to the next tab | [Move around](#move-around) |
| `,tp` | Go to the previous tab | [Move around](#move-around) |
| `,tt` | Open or close the file tree | [Move around](#move-around) |
| `,h` `,j` `,k` `,l` | Go to the window on the left / below / above / on the right | [Move around](#move-around) |
| `,n` | Show the current file in the file tree | [Move around](#move-around) |
| `,r` | Refresh the file tree | [Move around](#move-around) |
| `,u` | Show the undo history as a tree | [Save](#save-and-format) |
| `Space` | Open the command line | [Reading the keys](#reading-the-keys) |
| `jj` | *Insert*: go back to normal mode | [Reading the keys](#reading-the-keys) |
| `n` / `N` | Go to the next / previous search match, centred on the screen | [Move around](#move-around) |
| `s` | Jump to any spot on screen with a label (also *visual*, and after `d`, `c` or `y`) | [Move around](#move-around) |
| `S` | Select a piece of code by its structure (also *visual*, and after `d`, `c` or `y`) | [Move around](#move-around) |
| `gd` | Go to the definition | [Code](#understand-and-change-code) |
| `]h` / `[h` | Go to the next / previous git change | [Git](#git) |
| `Tab` | Jump to the next edit suggestion (when they're on), otherwise go forward through the places you've been | [AI](#ai) |
| `<M-]>` / `<M-[>` | *Insert*: show the next / previous ghost text suggestion | [AI](#ai) |
| `F5` | Remove the trailing whitespace in the file | [Write](#write-code) |
| `Esc Esc` | *Terminal*: go to normal mode | [Shell](#terminal-and-shell) |
| ⌘-click | *iTerm2*: open a `file:line` from the terminal in Neovim | [iTerm2](#iterm2) |
| Double-tap ⌃ | *iTerm2*: show or hide the hotkey window | [iTerm2](#iterm2) |
| ⌃⌘W / ⌃⌘X | *iTerm2*: start / close the Frontend Workgroup | [iTerm2](#iterm2) |
| ⌃⌘1 – ⌃⌘4 | *iTerm2*: show the Dev server / Tests / Git / Shell pane in the Workgroup | [iTerm2](#iterm2) |

## Where things live

| Path | What |
| --- | --- |
| [setup.sh](setup.sh), [Brewfile](Brewfile) | The setup script, and the list of Homebrew tools it installs |
| [script/nvim-sync.lua](script/nvim-sync.lua) | The Neovim part of setup: installs the plugins at their recorded versions, the Treesitter parsers and the language servers |
| [zshrc](zshrc), [config/starship.toml](config/starship.toml) | The shell's settings, and the prompt's |
| `~/.zshrc.local` (not in the repo) | Settings for this Mac only, such as work proxies and tokens. [zshrc](zshrc) loads it. Copy it to a new Mac yourself |
| [z.sh](z.sh) | The `z` command for jumping to folders, a copy of [rupa/z](https://github.com/rupa/z) |
| [bin/copilot-auto](bin/copilot-auto) | Starts Copilot CLI, on your local model when one is running |
| [bin/dev](bin/dev) | The `dev server` and `dev test` commands |
| [config/iterm2/profiles.json](config/iterm2/profiles.json) | iTerm2's Dotfiles and Hotkey profiles: colours, font, keys, the tab status rules and ⌘-click |
| [config/iterm2/workgroup.json](config/iterm2/workgroup.json) | The Frontend Workgroup. [script/iterm-workgroup.py](script/iterm-workgroup.py) adds it to iTerm2's settings |
| [bin/nvim-open](bin/nvim-open), [nvim/lua/config/iterm.lua](nvim/lua/config/iterm.lua) | Opening ⌘-clicked files in Neovim, and Neovim's tab status and notifications |
| [nvim/init.lua](nvim/init.lua) | Neovim's starting point. It loads the general settings in [nvim/lua/config/](nvim/lua/config) (options, keys, autosave, status line), then one file per area in [nvim/lua/plugins/](nvim/lua/plugins) |
| [nvim/lua/config/keymaps.lua](nvim/lua/config/keymaps.lua) | The keys that don't belong to a plugin |
| [nvim/lua/config/debug.lua](nvim/lua/config/debug.lua) | The debug configurations that `,ds` offers |
| [nvim/lua/config/test_report.lua](nvim/lua/config/test_report.lua) | What Vitest and Jest runs show in the status line and message line, and stopping them with `,mx` |
| [nvim/lua/config/test_list.lua](nvim/lua/config/test_list.lua) | The test list (`,mt`) |
| [nvim/lua/config/package_scripts.lua](nvim/lua/config/package_scripts.lua) | Running `package.json` scripts in their own iTerm2 panes, below Neovim (`,pp`, `,pl`, `,px`) |
| [nvim/lua/config/project_tests.lua](nvim/lua/config/project_tests.lua) | Which kinds of tests a project has, for the status line and the test list, and where its Playwright folders are |
| [nvim/lua/config/mason.lua](nvim/lua/config/mason.lua) | The language servers and tools that Mason installs |
| [nvim/lua/config/ai.lua](nvim/lua/config/ai.lua) | AI: choosing between the local model and Copilot, and turning suggestions on and off |
| [nvim/lua/config/review.lua](nvim/lua/config/review.lua) | Reviewing a branch (`,gv`) |
| [nvim/snippets/](nvim/snippets) | The snippets, one file per kind of file. `react-hooks.lua` holds the hook snippets that .tsx files and React .ts files share. [nvim/lua/config/snippets.lua](nvim/lua/config/snippets.lua) has the helpers they use, such as naming a component after its file and checking the React version |
| [nvim/nvim-pack-lock.json](nvim/nvim-pack-lock.json) | The plugin versions every Mac gets. Commit it after updating plugins |
