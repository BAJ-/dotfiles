# Workflows

Everyday tasks, start to finish, with this setup's keys and snippets. Pick the one that matches what you're about to do and follow it while you work. Once the steps feel familiar, the **Keys** line under each one is enough of a reminder. Every key is also in the [README](README.md), and all of them are listed in its [key index](README.md#key-index).

## Index

**Every day**

- [Pick up where you left off](#pick-up-where-you-left-off): get back to the files you were working on
- [Find your way around code](#find-your-way-around-code): where something is defined, where it's used, what it returns
- [Change something in many files](#change-something-in-many-files): search and replace, by text or by code structure

**Terminal and dev server**

- [Start the dev environment](#start-the-dev-environment): Neovim, the dev server, the tests and git in one tab
- [Go from an error to the code](#go-from-an-error-to-the-code): ⌘-click a file and line in any output
- [Run a quick command from anywhere](#run-a-quick-command-from-anywhere): a terminal that drops down over any app
- [Know when something slow is done](#know-when-something-slow-is-done): notifications and the tab's status while you do something else
- [Dig through a long output](#dig-through-a-long-output): jump between commands, filter, select and copy

**Write React and TypeScript**

- [Build a component with its styles](#build-a-component-with-its-styles): the component, its markup and its CSS Module
- [Give a component state and effects](#give-a-component-state-and-effects): hooks, and moving them into a hook of your own
- [Share state with a context](#share-state-with-a-context): a context, its provider and its hook
- [Load data and handle errors](#load-data-and-handle-errors): fetch, check what came back, show it

**Fix problems**

- [Clear the problems in a file](#clear-the-problems-in-a-file): type and lint errors, in one file or the whole project
- [Find a bug with logs](#find-a-bug-with-logs): log values, then remove the logs again
- [Find a bug with the debugger](#find-a-bug-with-the-debugger): breakpoints in Node, Next.js, Vite and Electron

**Test**

- [Write tests as you go](#write-tests-as-you-go): Vitest or Jest, run again on every save
- [Fix a failing test](#fix-a-failing-test): from the failure to the line, and into the debugger
- [Run end-to-end tests with Playwright](#run-end-to-end-tests-with-playwright): in a terminal, the Inspector or UI mode

**Refactor**

- [Rename and move things](#rename-and-move-things): names and files, with every import following

**Review and ship**

- [Review a pull request](#review-a-pull-request): someone else's changes, file by file, with go to definition working
- [Get your branch ready for review](#get-your-branch-ready-for-review): review your own changes, check them, commit, open the pull request

**Config and docs**

- [Edit a GitHub Actions workflow](#edit-a-github-actions-workflow): checked by GitHub's own Actions server
- [Edit package.json, tsconfig.json and other config](#edit-packagejson-tsconfigjson-and-other-config): keys and values from the file's schema
- [Write docs in Markdown](#write-docs-in-markdown): links that complete and that you can follow

**When you need it**

- [Ask AI about some code](#ask-ai-about-some-code): chat, ghost text and the agent, all off until you start them
- [Get back something you changed](#get-back-something-you-changed): undo history and git
- [When something stops working](#when-something-stops-working): restart, check, update

## Before you start

- `,` is the leader key: `,ff` is `,`, then `f`, then `f`. Keys work in normal mode unless marked *insert* or *visual*.
- iTerm2's keys use the Mac symbols: ⌘ Command, ⌥ Option, ⌃ Control, ⇧ Shift.
- **Snippets and the completion menu:** type the trigger (`rafc`), press `Tab` to select it in the menu and `Enter` to expand it. Type into the first field, then `Tab` goes to the next one. If the menu opened while you typed in a field, close it with `<C-e>` before that `Tab`. Only then, though: with no menu open, `<C-e>` types the character from the line below.
- Files save themselves a second after you leave insert mode, so the steps don't say `:w`. Saving with `:w` yourself also applies ESLint's fixes.
- Forgot what comes next? Press `,` (or `g`, `[`, `]`) and wait for the list.

## Every day

### Pick up where you left off

*Start of the day, or back after a break.*

1. In a terminal, `z` and part of the project's folder name goes there (`z myapp`). ⌃⌘W starts the dev server and the tests beside it ([Start the dev environment](#start-the-dev-environment)), and `nvim .` opens the project with the file tree.
2. `,gf` lists the files you've changed and not committed. `Tab` marks the ones you want and `Enter` opens them side by side.
3. Everything committed already? `,gv` shows what your branch changes compared with main, one file at a time: `]q` goes to the next file. `,gv` again closes it.
4. `,ff` and a few letters of a name open any other file. `,fb` lists the open files, and `[b` / `]b` step through them.
5. `,tt` hides the tree when you need the room, and `,n` brings it back at the current file.

**Keys:** `z` → ⌃⌘W → `nvim .` → `,gf` → `,gv` → `,ff` / `,fb` → `,tt` / `,n`

### Find your way around code

*Code you didn't write, or don't remember: where `useAuth` comes from, what uses it, what it returns.*

1. `,fg` and `useAuth -- *.tsx` searches only .tsx files (`useAuth -- *.tsx !*.test.*` leaves the tests out). `Enter` opens a match.
2. `gd` on a name goes to its definition, `<C-o>` comes back and `Tab` goes forward again.
3. `K` shows its type and docs, and `K` again moves into them, to scroll or copy. `,ci` shows parameter names and inferred types in the code itself.
4. `,cr` lists everywhere it's used, with a preview. `,cv` opens the definition in a split on the right, so you can read it next to the code that uses it.
5. `,cs` lists the components, functions and types in the file: a few letters and `Enter` jump to one.
6. In a long file, the component, function or `describe` you're in stays at the top of the window. To jump anywhere on screen, press `s`, type the first characters at that spot, then the label that appears there.
7. `,fr` brings back your last search as you left it, to open the next match.

**Keys:** `,fg` → `gd` / `<C-o>` → `K` → `,cr` → `,cv` → `,cs` → `s` → `,fr`

### Change something in many files

*Text that isn't a TypeScript name, like a CSS class, a test id or a string, or the same code change in many places. To rename a variable, function, component or type, use `grn` instead ([Rename and move things](#rename-and-move-things)).*

1. Put the cursor on the word, or select the text, and press `,fs`. The search field is already filled in.
2. `Tab` goes to the replace field: type the new text. `Tab` again to limit it to some files, such as `*.tsx` or `src/**`.
3. Underneath, every match is listed with the replacement applied. `Enter` opens one, and `Down` / `Up` preview the next / previous one.
4. `\r` replaces them all, or `\j` one at a time. `\q` sends them to the quickfix list instead, to make the changes yourself with `]q`.
5. To match code rather than text, `\e` switches to ast-grep. Search for `console.log($$$ARGS)` and replace it with `logger.debug($$$ARGS)`: every call changes and keeps its arguments, even when they span several lines.
6. `\c` closes it, and `,et` type-checks the project to make sure everything still fits.

**Keys:** `,fs` → `Tab` → `\r` (or `\e` for ast-grep) → `\c` → `,et`

## Terminal and dev server

### Start the dev environment

*Starting work on a project: the code, the running app, its tests and git, all in one tab.*

1. In a terminal, `z myapp` goes to the project. ⌃⌘W turns the tab into the Frontend Workgroup: the right-hand third starts the dev server, and the tests, Git and a shell start behind it.
2. `nvim .` in the pane on the left.
3. The dev server's output stays in view on the right. The tab's dot and word say *ready*, or *error* when the app doesn't build.
4. ⌃⌘2 brings the tests forward: they run again for every change you save, starting with the tests your changes touch. ⌃⌘3 shows Git (`tig`), ⌃⌘4 a shell for `npm install` and the like, and ⌃⌘1 the dev server again. Each puts the cursor in that pane, and ⌥⌘← takes you back to Neovim.
5. A command in one of them stopped? Its pane drops to a shell: `dev server` or `dev test` starts it again.
6. Done for the day? ⌃⌘X closes the Workgroup's panes; your own session, and Neovim in it, stay.

**Keys:** `z` → ⌃⌘W → `nvim .` → ⌃⌘1 – ⌃⌘4 → ⌥⌘← → ⌃⌘X

### Go from an error to the code

*A build error, a failing test or a stack trace names a file and a line.*

1. Hold ⌘ and click the path, like `src/components/UserCard.tsx:42:7`: Neovim opens the file at that line and column. The Neovim working on that project gets it, even in another tab or in the middle of typing, and its pane comes forward.
2. No Neovim open for that project? A new tab starts one, at that line.
3. `<C-o>` takes you back to where you were before.
4. Web addresses open in the browser the same way.

**Keys:** ⌘-click → `<C-o>`

### Run a quick command from anywhere

*A quick `gh pr status`, `git log` or `npm view react version` without leaving what you're doing, in any app.*

1. Double-tap ⌃: a terminal drops down from the top of the screen, over whatever app you're in, on any Space.
2. Run the command; `z` takes you to any project from there.
3. Double-tap ⌃ again, or click outside it, and it goes away. It keeps its state, so the output is still there next time.
4. The first time, macOS asks you to give iTerm2 Accessibility access: that's how it notices the double-tap.

**Keys:** double-tap ⌃ → command → double-tap ⌃

### Know when something slow is done

*An install, a build or the whole test suite takes a while, and you'd rather do something else meanwhile.*

1. Started something slow in a terminal? ⌥⌘A, and a notification tells you when it finishes. Go and do something else.
2. Tests (`,ma`, `,ml`) and type checks (`,et`) in Neovim tell you by themselves: switch to another app or pane, and a notification says *2 tests failing* or *No type errors* when they're done.
3. Meanwhile the tab's dot shows how it's going: *testing* while it runs, then the result.
4. With several projects open, ⌥⇧⌘C (Cockpit) lists every session's status in one place, the Workgroup's hidden panes too.
5. Clicking a notification takes you to the session it came from.

**Keys:** ⌥⌘A → `,ma` / `,et` → ⌥⇧⌘C

### Dig through a long output

*A build or test run printed hundreds of lines, and you need one part of them.*

1. ⇧⌘↑ jumps to the previous command and ⇧⌘↓ to the next: every prompt is marked.
2. ⇧⌘A selects the last command's whole output, and ⌘C copies it, to paste into an issue or an AI chat.
3. ⌥⇧⌘F filters: type `error` and only the lines with it stay. ⌘F finds and highlights instead.
4. ⇧⌘C starts copy mode: move and select with the keyboard, vim-style.
5. A `file:line` in there? ⌘-click it ([Go from an error to the code](#go-from-an-error-to-the-code)).
6. In Neovim's terminal (`,tm`), `[[` / `]]` jump between prompts, and Neovim's own search and yank work as in any file.

**Keys:** ⇧⌘↑ / ⇧⌘↓ → ⇧⌘A + ⌘C → ⌥⇧⌘F → ⇧⌘C → ⌘-click

## Write React and TypeScript

### Build a component with its styles

*A new `UserCard` in `src/components`, styled with its own CSS Module.*

1. Open a file in `src/components` and press `,n`: the tree opens there. `a`, type `UserCard.tsx`, `Enter`, then `Enter` again to open it.
2. `rafc`, `Tab`, `Enter` writes the component, named after the file, with its `UserCardProps` interface.
3. Fill in its fields, with `Tab` between them: the props' types (`name: string`), the props it takes (`name`), then the JSX.
4. In the JSX, Emmet writes markup for you: `div.card>h2+p`, `Tab`, `Enter` gives a `div` with `className="card"`, an `h2` and a `p`.
5. For a list, `jmap` asks for the array (`users`), `Tab`, the item (`user`, which also fills in `key={user.id}`), `Tab`, the element (`li`, closing tag included), `Tab`, its content.
6. Now the styles: `,n`, `a`, `UserCard.module.css`. Inside a value, `var(--` lists the CSS variables your project defines.
7. Back in `UserCard.tsx`, add `import styles from './UserCard.module.css'` at the top; the file name completes after `'./`. On `className="card"`, `ca"` and type `{styles.ca`: the menu lists the classes in the CSS file. `Tab`, `Enter`, then `}`. `gd` on `card` jumps to its rule.
8. To use the component, type `<UserC` in another one, then `Tab`, `Enter`: the import is added for you.

**Keys:** `,n` → `a` → `rafc` → `div.card>h2+p` → `jmap` → `a` → `styles.` → `gd` → `<UserC`

### Give a component state and effects

*The card should open and close, close on Escape, and know how wide the window is.*

1. Above the `return`, `us`: name the state `open`, `Tab`, start value `false`. The setter follows the name: `setOpen`.
2. For state that starts out empty, `ust`: name it `user`, `Tab`, the type `User | null`, `Tab`, start value `null`.
3. `uel` adds an event listener and removes it again: type `keydown`, `Tab`, keep `window`, `Tab`, write the handler (its `event` is already a `KeyboardEvent`), `Tab`, the dependencies.
4. Snippets don't add imports. On `useState`, `,ca` offers "Add import from react", and "Add all missing imports" once more than one is missing.
5. Logic worth reusing goes in a hook: `,n`, `a`, `useWindowSize.ts`. There, `hook` writes `export const useWindowSize = () => {…}`, named after the file; `Tab` twice takes you into its body. Add `us` (`width`, `window.innerWidth`) and `uel` (`resize`, with `setWidth(window.innerWidth)` in the handler), then type `width.ret` and pick `.return`. `,ca` adds the imports.
6. Back in the component, `useWin`, `Tab`, `Enter` writes `useWindowSize()` and imports it.
7. `ucb`, `um` and `ur` work the same way for `useCallback`, `useMemo` and `useRef`.

**Keys:** `us` / `ust` → `uel` → `,ca` → `a` → `hook` → `.return` → `useWin`

### Share state with a context

*Several components need the same thing, like the theme or the signed-in user.*

1. `,n`, `a`, `ThemeContext.tsx`, and open it.
2. `ctx` writes the context, a `ThemeProvider`, and a `useTheme` hook that throws a clear error when it's used outside the provider. The name comes from the file and changes everywhere if you type another one; `Tab`, the value's type (`dark: boolean`), `Tab`, the value.
3. `,ca` on `createContext`, then "Add all missing imports".
4. Wrap the app in the provider. In the root component, `S` and the label on the element to wrap selects it. `c`, type `<ThemeProvider>` (its closing tag appears), `Esc`, `p`. Saving lines it all up.
5. In a component that needs it, type `const { dark } = useThe`, then `Tab`, `Enter`: you get `useTheme()` and its import.
6. `gd` on `useTheme` goes to the context, and `,cr` on `ThemeProvider` shows where it's used.

**Keys:** `a` → `ctx` → `,ca` → `S` + `c` + `<ThemeProvider>` + `Esc` + `p` → `useThe`

### Load data and handle errors

*Fetch a user from an API, make sure it really is one, then show it.*

1. In `src/api/users.ts`, type `export af`, `Tab`, `Enter`: the name (`loadUser`), `Tab`, the parameters (`id: string`), `Tab`, and you're in its body.
2. `fetchj`: the URL (`` `/api/users/${id}` ``), `Tab`, keep `data`. It fetches, throws if the response isn't OK, and parses the JSON.
3. Check what came back. On the next line, type `!isUser(data).if` and pick `.if`: `if (!isUser(data)) {…}`. Inside it, `tne` and your message: ``throw new Error(`…`)``.
4. Below the `if`, type `data.ret` and pick `.return`: `return data`.
5. Write `isUser` below the function with `guard`: type `User` (it fills in both places), `Tab`, then the check, like `typeof value === 'object' && value !== null && 'id' in value`. TypeScript now knows `loadUser` returns a `User` (`,ca` on `User` imports the type if needed).
6. Two requests at once: `pa` asks for the names (`user, teams`), `Tab`, then the calls (`loadUser(id), loadTeams(id)`).
7. In the component, `ust` (`user`, `User | null`, `null`), then `ue` with `loadUser(id).then(setUser)`, `Tab`, and `id` as its dependency. Where you'd rather catch the error, `tc` wraps code in `try` / `catch`.

**Keys:** `export af` → `fetchj` → `.if` + `tne` → `.return` → `guard` → `pa` → `ust` + `ue`

## Fix problems

### Clear the problems in a file

*Red and yellow marks after a change, or before you commit.*

1. `]d` jumps to the next problem and `[d` to the previous one; `,en` / `,ep` do the same and show the message.
2. `,ed` shows the whole message, for TypeScript's long ones.
3. `,ca` lists the fixes: add the missing import, remove what's unused, use the name it probably meant…
4. `K` on a name shows its type, to compare with what TypeScript expected.
5. Changed a type, or props that other files pass? `,et` type-checks the whole project in the background and puts the errors in the quickfix list. `[Q` goes to the first one and `]q` to each next one, whatever file it's in. In a big project that takes a while: the tab says *type-checking*, and if you switch to another app, a notification tells you when it's done.
6. `:w`, instead of waiting for autosave, also applies ESLint's fixes, such as removing unused imports.

**Keys:** `]d` → `,ed` → `,ca` → `K` → `,et` → `[Q` / `]q` → `:w`

### Find a bug with logs

*Something has the wrong value and you want to see it.*

1. Type `.log` after any expression: `user.profile.log` gives `console.log(user.profile)`, and `items.filter(isOpen).log` logs the whole chain.
2. Keep the dev server in view: in the Workgroup it runs on the right (⌃⌘1 brings it forward). Without the Workgroup: `,sv`, `,tm`, `dev server`, then `Esc Esc` and `,h` to get back to your code. Server code logs there; browser code logs to the browser's console. An error with a `file:line`? ⌘-click it.
3. Change the code and look again. Files save themselves, so the dev server reloads without `:w`.
4. Found it? Remove the logs: `,fg`, `console.log`, `<M-a>` marks every match and `Enter` puts them in the quickfix list. `[Q` goes to the first one, `dd` deletes it, `]q` goes to the next. Leave the logs that were there before you started.
5. `,gv` shows everything your branch changes, to make sure none are left.

**Keys:** `.log` → ⌃⌘1 (or `,sv` + `,tm`) → ⌘-click → `,fg` → `<M-a>` + `Enter` → `[Q` → `dd` → `]q`

### Find a bug with the debugger

*Logs aren't enough: you want to stop the code and look around.*

1. `,db` on the line where it should stop. `,dB` stops only when a condition is true, like `user.id === '42'`.
2. `,ds` and pick what to run:
   - a script or a TypeScript file: **Node: current file**
   - Next.js: **Next.js: server (dev script)** for route handlers and server components. For client components as well, `,ds` again, **Start additional session**, then **Next.js: client in Chrome (:3000)**
   - Vite: start the dev server (⌃⌘W for the Workgroup, or `,sv`, `,tm`, `dev server`), then **Vite: client in Chrome (:5173)**
   - Electron: **Electron: main + renderer**
3. Use the app until it stops at your breakpoint. The debug view shows the variables (`S`), your watch expressions (`W`, where `i` adds one) and a REPL (`R`) to run code right there.
4. `,dn` steps over, `,di` into and `,do` out of a function, and `,dc` runs on to the next breakpoint. `,dl` shows the value under the cursor.
5. Fixed it? `,de` ends everything and clears the breakpoints. `,dr` runs the same configuration again.

**Keys:** `,db` → `,ds` → `,dn` / `,di` / `,do` → `,dl` → `,dc` → `,de`

## Test

### Write tests as you go

*Tests for new code while you write it, with Vitest or Jest.*

1. Next to `UserCard.tsx`: `,n`, `a`, `UserCard.test.tsx`. `,sv` and `,ff` open the component beside it.
2. `,mw` watches the test file: it runs again on every save, and files save when you leave insert mode, so the results keep up as you write. `,mw` again stops watching.
3. Results appear next to each test. A failure is marked on the line that failed, and `]d` goes there.
4. `,mr` runs only the test under the cursor, `,ma` the whole file, and `,ml` the last run again from any file.
5. `,mo` shows the output of the test under the cursor, `console.log`s included, and `,ms` a summary of every test.
6. In a Jest project, `,fn` copies the test file's name, and `testfile` in a terminal runs it with coverage for the file it tests.
7. In the Workgroup, the Tests pane (⌃⌘2) also runs every test your changes touch, in all files, on every save. Its status shows *3 failing* or *tests pass*, and ⌘-click on a failure opens it in Neovim.

**Keys:** `a` → `,sv` + `,ff` → `,mw` → `,mr` / `,ma` → `,mo` → `,ms` → ⌃⌘2

### Fix a failing test

*A test fails, here or in CI.*

1. `,ma` runs the file. `,ms` opens the summary: `J` jumps to the next failed test, `o` shows its output and `i` takes you to it. Failing in the Workgroup's Tests pane, or in CI output in a terminal? ⌘-click the failure's `file:line` instead.
2. In the file, `]d` lands on the failing line with the assertion's message, and `,ed` shows all of it, expected and received.
3. `gd` on the function under test opens it, or `,cv` opens it in a split, to keep the test in view.
4. Still not clear? `,db` on a line in the test or in the code, then `,md` on the test: it runs under the debugger and stops there. The keys from [Find a bug with the debugger](#find-a-bug-with-the-debugger) work from there.
5. After the fix, `,ml` runs that test again, from whichever file you're in.

**Keys:** `,ma` → `,ms` + `J` + `o` → `]d` → `,cv` → `,db` + `,md` → `,ml`

### Run end-to-end tests with Playwright

*Specs are the files that import `@playwright/test`.*

1. `,mr` runs the test under the cursor and `,ma` the whole file, in a terminal below; the cursor stays in the spec.
2. `,mi` runs the test under the cursor in a browser you can see, with the Playwright Inspector, paused at the start: step through it and try locators there.
3. `,mu` opens Playwright's UI mode, to run and watch any test with its timeline.
4. `,md` debugs the test under the cursor in Neovim instead, with breakpoints (`,db`) in the spec and in the code it imports.
5. `,ml` runs the last tests again. `,j` goes down to the terminal to read the output, and `,k` back up.

**Keys:** `,mr` / `,ma` → `,mi` → `,mu` → `,md` → `,ml`

## Refactor

### Rename and move things

*A name no longer fits, or a file belongs somewhere else.*

1. `grn` on a variable, function, component or type, then the new name and `Enter`: every file that uses it changes.
2. To rename a file, `,n` shows it in the tree, and `e` edits its name without the extension; `Enter`. Every import of it changes.
3. To move a file, `x` on it, then `p` on the folder it belongs in. The imports change here too.
4. The files whose imports changed are edited but not saved yet: `:wa` saves them all.
5. Renamed a component's file? `grn` the component and its `Props` interface too, so the names match.
6. `,et` type-checks the whole project to catch anything that didn't follow.

For text that isn't a name in the code, like a string, a CSS class or a test id, see [Change something in many files](#change-something-in-many-files).

**Keys:** `grn` → `,n` → `e` / `x` + `p` → `:wa` → `,et`

## Review and ship

### Review a pull request

*Someone asked for your review.*

1. `:!gh pr checkout 123` switches to the pull request's branch, and open files reload.
2. `,gv` opens the review in a new tab: what the pull request changes since it left main, with the original on the left and the new version on the right. If it targets another branch, use `:Review origin/that-branch` instead.
3. `]q` / `[q` go from file to file, and `]c` / `[c` from change to change.
4. The right side is the real file, so `gd`, `K` and `,cr` work: check how a changed function is used elsewhere. `,gb` shows who last changed a line and why.
5. Run what it touches: `,ma` in a test file, and `,et` for the types.
6. To comment on some lines, select them (`V`) and `,gy`: paste the link into your comment on GitHub and it shows the code. `,go` opens the lines on GitHub.
7. `,gv` closes the review, and `:!git switch -` takes you back to your own branch.

**Keys:** `:!gh pr checkout` → `,gv` → `]q` / `]c` → `gd` / `K` / `,cr` → `,gb` → `,gy` → `,gv`

### Get your branch ready for review

*Before you push and open a pull request.*

1. `,gv` shows your branch the way a reviewer will see it: `]q` from file to file and `]c` from change to change. Fix what you find on the right as you go: leftover logs, commented-out code, a missed rename. `,gv` again closes it.
2. `,et` type-checks the project, and `,ma` runs the tests in a test file.
3. To commit only some of your changes: `]h` goes to the next change, `,gp` previews it, `,gs` stages it and `,gr` throws it away.
4. In the Workgroup, ⌃⌘4 opens the Shell beside your code (without it, `,sv` and `,tm`): `git commit -m "Add user card"`, `git push`, then `gh pr create --web` opens the new pull request's page on GitHub. ⌥⌘← takes you back to the code (`Esc Esc` and `,h` from Neovim's terminal).
5. Afterwards, `,go` on any line opens it on GitHub.

**Keys:** `,gv` → `]q` / `]c` → `,et` → `]h` + `,gp` + `,gs` → ⌃⌘4 (or `,sv` + `,tm`) → `gh pr create --web`

## Config and docs

### Edit a GitHub Actions workflow

*A change to CI, a new job, a new step.*

1. `,ff`, type `ci.yml` and press `<M-h>`: `.github` is a hidden folder, so hidden files have to be included.
2. Problems show as you type, and `]d` goes to each: unknown keys, wrong values, misspelled action inputs (`fetch-depthh`) and contexts that don't exist (`github.shaa`).
3. Inside `${{ }}`, contexts complete: `github.` lists `sha`, `ref`, `event_name` and the rest.
4. `K` on a key explains it, and on an action (`uses: actions/checkout@v5`) it shows what the action does, with a link.
5. To point someone at a step, select it (`V`) and `,gy` to copy its GitHub link.

**Keys:** `,ff` + `<M-h>` → `]d` → `${{ github.` → `K` → `,gy`

### Edit package.json, tsconfig.json and other config

*package.json, tsconfig.json, devcontainer.json, ESLint and Prettier configs, and many more: anything with a published schema.*

1. `,ff` and the file's name.
2. Keys and values complete from the schema: in `compilerOptions`, typing `"modu` lists `module`, `moduleResolution` and the rest.
3. `K` on a key explains what it does.
4. Wrong keys and values show as problems: `]d` goes to each.

**Keys:** `,ff` → `"modu` → `K` → `]d`

### Write docs in Markdown

*A README, a design doc, notes.*

1. `,cs` lists the headings, to jump to one.
2. For a link, type `[text](#` and the menu lists the file's headings; after `(./` it lists files. A link to a file that doesn't exist shows as a problem.
3. `gd` on a link opens the file or jumps to the heading, and `<C-o>` comes back. `gx` opens a web link in the browser.
4. `grn` on a heading renames it, along with the links to it in the file.
5. Saving formats the file with Prettier, tables included.
6. `,gy` copies the GitHub link to the line or the selection, to share a section.

**Keys:** `,cs` → `(#` → `gd` / `<C-o>` → `grn` → `,gy`

## When you need it

### Ask AI about some code

*All AI is off until you start it. Chat and the agent only run while they're open.*

1. Select the code (`V` and a motion, or `S` and a label) and `,ac`: a chat opens with it. Type your question; `Enter` sends it (`<C-s>` in insert mode).
2. When it proposes changes to the file, `gv` shows the diff, `g2` accepts and `g3` rejects. `gy` copies the last code block, and `<C-c>` closes the chat.
3. Writing something repetitive? `,al` turns on ghost text: grey suggestions as you type, `Tab` accepts one (when the menu is closed) and `<M-]>` shows the next. `,al` again turns it off.
4. For a bigger job, `,aa` opens the agent (Copilot CLI) in a split. `,af` sends it the file and `,ap` offers ready-made prompts: explain, fix, tests, review…
5. If something doesn't answer, `:AIStatus` shows what's on and what's missing.

**Keys:** `V` + `,ac` → `g2` / `g3` → `,al` + `Tab` → `,aa` → `,af`

### Get back something you changed

*An edit went wrong, or you want an earlier version back.*

1. `u` undoes and `<C-r>` redoes, even after you've closed and reopened the file.
2. `,u` opens the undo tree. Move through it and the file follows; stop at the version you want, and `,u` closes the tree.
3. To get back what git has, `]h` goes to a change, `,gp` shows the old version and `,gr` puts it back.
4. `,gd` shows the whole file next to the version in git, side by side.

**Keys:** `u` / `<C-r>` → `,u` → `]h` + `,gp` + `,gr` → `,gd`

### When something stops working

*Completion is gone, errors don't update, or something just seems off.*

1. Completion, `gd` or the problems stopped working in a file: `:lsp restart`.
2. Still not right? `:checkhealth vim.lsp` shows which language servers run for the file, and why one doesn't.
3. Anything else odd: `:restart` restarts Neovim with the same files open, and `:checkhealth` checks the whole setup.
4. AI not answering: `:AIStatus`.
5. ⌘-click, the Workgroup or the Dotfiles profile missing in iTerm2: `./setup.sh` lists what's left to do, such as making Dotfiles the default profile or restarting iTerm2.
6. Every week or so, `./setup.sh` in the dotfiles folder brings everything up to date.

**Keys:** `:lsp restart` → `:checkhealth vim.lsp` → `:restart` → `./setup.sh`
