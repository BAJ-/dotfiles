# Workflows

Everyday tasks, start to finish, using this setup's keys and snippets. Pick the one that matches what you're about to do, and follow its steps while you work. Once the steps feel familiar, the **Keys** line at the end of each workflow is enough of a reminder. Every key is also explained in the [README](README.md), and listed in its [key index](README.md#key-index).

## Index

**Every day**

- [Pick up where you left off](#pick-up-where-you-left-off): get back to the files you were working on
- [Find your way around code](#find-your-way-around-code): where something is defined, where it's used, what it returns
- [Change something in many files](#change-something-in-many-files): search and replace, by text or by the structure of the code

**Terminal and dev server**

- [Start the dev environment](#start-the-dev-environment): Neovim, the dev server, the tests and git in one tab
- [Go from an error to the code](#go-from-an-error-to-the-code): ⌘-click a file and line in any output to open it in Neovim
- [Run a quick command from anywhere](#run-a-quick-command-from-anywhere): a terminal that drops down over any app
- [Run a package.json script](#run-a-packagejson-script): pick a script and run it in a pane below your code
- [Know when something slow is done](#know-when-something-slow-is-done): notifications and the tab's status while you do something else
- [Dig through a long output](#dig-through-a-long-output): jump between commands, filter, select and copy

**Write React and TypeScript**

- [Build a component with its styles](#build-a-component-with-its-styles): the component, its markup and its CSS Module
- [Give a component state and effects](#give-a-component-state-and-effects): hooks, and moving them into a hook of your own
- [Share state with a context](#share-state-with-a-context): a context, its provider and its hook
- [Load data and handle errors](#load-data-and-handle-errors): fetch data, check what came back, show it

**Fix problems**

- [Clear the problems in a file](#clear-the-problems-in-a-file): type and lint errors, in one file or the whole project
- [Find a bug with logs](#find-a-bug-with-logs): log values, then remove the logs again
- [Find a bug with the debugger](#find-a-bug-with-the-debugger): breakpoints in Node, Next.js, Vite and Electron

**Test**

- [Write tests as you go](#write-tests-as-you-go): Vitest or Jest tests that run again every time you save
- [Fix a failing test](#fix-a-failing-test): from the failure to the line, and into the debugger
- [Run a chosen set of tests](#run-a-chosen-set-of-tests): filter a list of every test, check some off and run them, from any file
- [Run end-to-end tests with Playwright](#run-end-to-end-tests-with-playwright): in a terminal, in the Inspector or in UI mode

**Refactor**

- [Rename and move things](#rename-and-move-things): names and files, with every import updated

**Review and ship**

- [Review a pull request](#review-a-pull-request): someone else's changes, file by file, with go to definition working
- [Get your branch ready for review](#get-your-branch-ready-for-review): review your own changes, check them, commit, open the pull request

**Config and docs**

- [Edit a GitHub Actions workflow](#edit-a-github-actions-workflow): checked as you type by GitHub's own Actions server
- [Edit package.json, tsconfig.json and other config](#edit-packagejson-tsconfigjson-and-other-config): keys and values that complete from the file's schema
- [Write docs in Markdown](#write-docs-in-markdown): links that complete and that you can follow

**When you need it**

- [Ask AI about some code](#ask-ai-about-some-code): chat, ghost text and the agent, all off until you start them
- [Get back something you changed](#get-back-something-you-changed): the undo history and git
- [When something stops working](#when-something-stops-working): restart, check, update

## Before you start

- **The leader key is `,`:** `,ff` means press `,`, then `f`, then `f`. Keys work in normal mode unless a step says otherwise. Words like picker, quickfix list and label are explained in the README's [Words used here](README.md#words-used-here).
- **iTerm2's keys** use the Mac symbols: ⌘ Command, ⌥ Option, ⌃ Control, ⇧ Shift.
- **Snippets:** type a snippet's trigger, such as `rafc`, press `Tab` to select it in the completion menu and `Enter` to insert it. The snippet's first field is selected, so you can start typing straight away, and `Tab` moves to the next field. If the completion menu pops up while you're typing in a field, press `<C-e>` to close it before you press `Tab`, or `Tab` moves through the menu instead. Only press `<C-e>` while the menu is open: without it, `<C-e>` copies the character from the line below.
- **Saving:** files save themselves a second after you leave insert mode, so the steps don't mention `:w`. When you do save with `:w` yourself, ESLint's automatic fixes run too, such as removing unused imports.
- **Forgot what comes next?** Press `,` (or `g`, `[` or `]`) and wait: a list of every key that can follow pops up.

## Every day

### Pick up where you left off

*Start of the day, or back after a break.*

1. In a terminal, type `z` and part of the project's folder name, like `z myapp`, to go there. Press ⌃⌘W to start the dev server and the tests beside it (see [Start the dev environment](#start-the-dev-environment)), then type `nvim .` to open the project in Neovim, with the file tree.
2. Press `,gf` to see the files you've changed and not committed yet. Press `Tab` on each one you want, then `Enter`: they open side by side.
3. If you've already committed everything, press `,gv` instead. It shows everything your branch changes compared with main, one file at a time: `]q` goes to the next file, and `,gv` again closes the review.
4. To open any other file, press `,ff` and type a few letters of its name. `,fb` lists the files you already have open, and `[b` / `]b` step through them.
5. Press `,tt` to hide the file tree when you need the room. `,n` brings it back with the current file selected.

**Keys:** `z` → ⌃⌘W → `nvim .` → `,gf` → `,gv` → `,ff` / `,fb` → `,tt` / `,n`

### Find your way around code

*Code you didn't write, or don't remember: where `useAuth` comes from, what uses it, what it returns.*

1. Press `,fg` and type `useAuth -- *.tsx` to search for `useAuth` in .tsx files only. `useAuth -- *.tsx !*.test.*` also leaves out the tests. Press `Enter` on a match to open it.
2. With the cursor on a name, press `gd` to go to its definition. `<C-o>` takes you back to where you were, and `Tab` forward again.
3. Press `K` on a name to see its type and docs. Press `K` again to move into that window, to scroll or copy. `,ci` shows parameter names and inferred types in grey inside the code.
4. Press `,cr` to list every place the name is used, with a preview of each. `,cv` opens the definition in a split on the right, so you can read it next to the code that uses it.
5. Press `,cs` to list the components, functions and types in the file. Type a few letters of one and press `Enter` to jump to it.
6. In a long file, the component, function or `describe` block you're in stays at the top of the window as you scroll. To jump to any spot you can see, press `s`, type the first one or two letters at that spot, then press the label that appears next to it.
7. `,fr` reopens your last search exactly as you left it, so you can open the next match.

**Keys:** `,fg` → `gd` / `<C-o>` → `K` → `,cr` → `,cv` → `,cs` → `s` → `,fr`

### Change something in many files

*Text that isn't a name in your code, like a CSS class, a test id or a string, or the same change to code in many places. To rename a variable, function, component or type, use `grn` instead (see [Rename and move things](#rename-and-move-things)).*

1. Put the cursor on the word, or select the text, and press `,fs`. A search-and-replace window opens with the search field already filled in.
2. Press `Tab` to go to the replace field and type the new text. Press `Tab` again if you want to limit the change to some files, with a pattern such as `*.tsx` or `src/**`.
3. Below the fields, every match is listed with the replacement applied, so you can check them first. `Enter` opens a match in its file, and `Down` / `Up` preview the next / previous one.
4. Press `\r` to replace them all, or `\j` to replace them one at a time. To make the changes yourself instead, `\q` puts the matches in the quickfix list, and `]q` takes you from one to the next.
5. To match code rather than text, press `\e` to switch to ast-grep. Searching for `console.log($$$ARGS)` and replacing it with `logger.debug($$$ARGS)` changes every call and keeps its arguments, even when they span several lines.
6. Press `\c` to close the window, then `,et` to type-check the project and make sure everything still fits.

**Keys:** `,fs` → `Tab` → `\r` (or `\e` for ast-grep) → `\c` → `,et`

## Terminal and dev server

### Start the dev environment

*Starting work on a project: the code, the running app, its tests and git, all in one iTerm2 tab.*

1. In a terminal, type `z myapp` to go to the project. Press ⌃⌘W to turn the tab into the Frontend Workgroup: the right-hand third of the tab starts the dev server, and the tests, git and a shell start in panes behind it.
2. Type `nvim .` in the pane on the left.
3. The dev server's output stays in view on the right. The tab's coloured dot and word say *ready*, or *error* when the app doesn't build.
4. Press ⌃⌘2 to bring the tests to the front: they run again for every change you save, starting with the tests your changes affect. ⌃⌘3 shows git (`tig`), ⌃⌘4 a shell for things like `npm install`, and ⌃⌘1 the dev server again. Each of them also moves the cursor into that pane, and ⌥⌘← takes you back to Neovim.
5. If the command in one of those panes stops, a shell takes its place: type `dev server` or `dev test` to start it again.
6. Done for the day? Press ⌃⌘X to close the Workgroup's panes. Your own pane, with Neovim in it, stays open.

**Keys:** `z` → ⌃⌘W → `nvim .` → ⌃⌘1 – ⌃⌘4 → ⌥⌘← → ⌃⌘X

### Go from an error to the code

*A build error, a failing test or a stack trace names a file and a line.*

1. Hold ⌘ and click the file's path, like `src/components/UserCard.tsx:42:7`: Neovim opens the file at that line and column. If Neovim is open on that project, even in another tab or in the middle of typing, the file opens there and its pane comes to the front.
2. If no Neovim is open on that project, a new tab starts one, at that line.
3. In Neovim, `<C-o>` takes you back to where you were before.
4. Web addresses open in your browser the same way.

**Keys:** ⌘-click → `<C-o>`

### Run a quick command from anywhere

*A quick `gh pr status`, `git log` or `npm view react version` without leaving what you're doing, in any app.*

1. Double-tap ⌃: a terminal drops down from the top of the screen, over whatever app you're in, on any desktop.
2. Run your command. `z` takes you to any project from there.
3. Double-tap ⌃ again, or click outside the terminal, and it slides away. It keeps its state, so your output is still there next time.
4. The first time you double-tap, macOS asks you to give iTerm2 Accessibility access. iTerm2 needs it to notice the double-tap.

**Keys:** double-tap ⌃ → your command → double-tap ⌃

### Run a package.json script

*A build, a lint or any other script from `package.json`, in a pane of its own below your code, while you go on in Neovim.*

1. Press `,pp`: every script in the project's `package.json` files is listed, and scripts of packages in subfolders, like `tests/e2e`, show their folder. Type a few letters of the one you want, like `bui`, and the preview beside the list shows it in its `package.json`.
2. Press `Enter`: a new iTerm2 pane opens below Neovim, named after the script, like *build · my-app*, and the script runs there, in its package's folder, with the project's package manager. The cursor stays in Neovim, so you can go on working while you keep an eye on it.
3. The pane stays open when the script ends, so its output is still there to read. ⌥⌘↓ takes you down into it, to scroll or to run the script again with ↑ and `Enter`, and ⌥⌘↑ back up to Neovim.
4. To run it again from Neovim, press `,pl`, or pick it with `,pp`: it runs again in its pane. If it's still running, it isn't started twice.
5. A second script opens in a pane beside the first, along the bottom. Need the room for a while? ⇧⌘↩ in Neovim gives it the whole tab and hides the script panes, which keep running, and ⇧⌘↩ again brings them back.
6. Done with them? `,px` closes all the script panes from Neovim, stopping any script that's still running. ⌘W closes just the pane you're in.
7. For the dev server and the tests while you work, the Frontend Workgroup is usually handier: see [Start the dev environment](#start-the-dev-environment).

**Keys:** `,pp` → `Enter` → ⌥⌘↓ / ⌥⌘↑ → `,pl` → ⇧⌘↩ → `,px`

### Know when something slow is done

*An install, a build or the whole test suite takes a while, and you'd rather do something else meanwhile.*

1. Started something slow in a terminal? Press ⌥⌘A, and a notification tells you when it finishes. You can go and do something else.
2. Tests (`,ma`, `,ml`) and type checks (`,et`) that you run in Neovim tell you by themselves: switch to another app or pane, and when they're done a notification says something like *2 tests failing* or *No type errors*.
3. Meanwhile, the tab's coloured dot and word show how it's going: *testing* while the tests run, then the result.
4. With several projects open, press ⌥⇧⌘C to open the Cockpit: every session's status in one list, including the Workgroup's hidden panes.
5. Click a notification to go to the session it came from.

**Keys:** ⌥⌘A → `,ma` / `,et` → ⌥⇧⌘C

### Dig through a long output

*A build or test run printed hundreds of lines, and you need one part of them.*

1. Press ⇧⌘↑ to jump to the previous command you ran, and ⇧⌘↓ to the next. iTerm2 knows where each command starts thanks to its shell integration.
2. Press ⇧⌘A to select the last command's whole output, then ⌘C to copy it, for example to paste into an issue or an AI chat.
3. Press ⌥⇧⌘F to filter: type `error`, and only the lines that contain it stay visible. ⌘F finds and highlights matches instead.
4. Press ⇧⌘C for copy mode: move and select text with the keyboard, using Vim's keys.
5. See a `file:line` in there? ⌘-click it to open it in Neovim (see [Go from an error to the code](#go-from-an-error-to-the-code)).
6. In a terminal inside Neovim (`,tm`), press `Esc Esc` to leave terminal mode first. Then `[[` / `]]` jump between the commands you ran, and Neovim's own search (`/`) and copy (`y`) work as in any file.

**Keys:** ⇧⌘↑ / ⇧⌘↓ → ⇧⌘A + ⌘C → ⌥⇧⌘F → ⇧⌘C → ⌘-click

## Write React and TypeScript

### Build a component with its styles

*A new `UserCard` in `src/components`, styled with its own CSS Module.*

1. Open any file in `src/components` and press `,n`: the file tree opens with that file selected. Press `a` to add a file, type `UserCard.tsx` and press `Enter`, then `Enter` again to open the new file.
2. Type `rafc`, then `Tab` and `Enter` to insert the snippet. It writes the component, named after the file, with a `UserCardProps` interface for its props.
3. Fill in the snippet's fields, pressing `Tab` to go from one to the next: the props' types (`name: string`), the props the component takes (`name`), then its JSX.
4. In the JSX, Emmet writes markup for you: type `div.card>h2+p`, then `Tab` and `Enter`, and you get a `div` with `className="card"` holding an `h2` and a `p`.
5. For a list, insert the `jmap` snippet the same way. Its fields ask for the array (`users`), the item's name (`user`, which also fills in `key={user.id}`), the element (`li`, closing tag included) and its content, with `Tab` between them.
6. Now the styles: press `,n`, then `a`, and create `UserCard.module.css`. While you write a value, typing `var(--` lists the CSS variables your project defines.
7. Back in `UserCard.tsx`, add `import styles from './UserCard.module.css'` at the top; after `'./` the menu completes the file's name. Then put the cursor on `"card"` in `className="card"` and type `ca"`, which deletes the quoted text and lets you type in its place. Type `{styles.ca`: the menu lists the classes in the CSS file. Pick `card` with `Tab` and `Enter`, then type `}`. `gd` on `card` jumps to its rule in the CSS file.
8. To use the component, type `<UserC` in another component, then `Tab` and `Enter`: the name is completed, and the import is added at the top of the file for you.

**Keys:** `,n` → `a` → `rafc` → `div.card>h2+p` → `jmap` → `a` → `styles.` → `gd` → `<UserC`

### Give a component state and effects

*The card should open and close, close on Escape, and know how wide the window is.*

1. Above the component's `return`, insert the `us` snippet (type `us`, then `Tab` and `Enter`). Name the state `open`, press `Tab`, and give it the start value `false`. The setter's name follows as you type: `setOpen`.
2. For state that starts out empty, use `ust`: name it `user`, press `Tab`, give it the type `User | null`, press `Tab` again, and give it the start value `null`.
3. `uel` adds an event listener, and removes it again when the component goes away. Type the event, `keydown`, and press `Tab`. Keep `window` as the target and press `Tab` again. Write what should happen in the handler (its `event` is already typed as a `KeyboardEvent`), then press `Tab` once more for the dependencies.
4. Snippets don't add imports. Put the cursor on `useState` and press `,ca`: it offers "Add import from react", and "Add all missing imports" when more than one is missing.
5. Logic worth reusing goes in a hook of its own. Press `,n`, then `a`, and create `useWindowSize.ts`. There, the `hook` snippet writes `export const useWindowSize = () => {…}`, named after the file; press `Tab` twice to get into its body. Add `us` (named `width`, starting at `window.innerWidth`) and `uel` (for `resize`, with `setWidth(window.innerWidth)` in the handler). Then type `width.ret` and pick `.return` to write `return width`. `,ca` adds the imports.
6. Back in the component, type `useWin`, then `Tab` and `Enter`: it writes `useWindowSize()` and imports it for you.
7. `ucb`, `um` and `ur` work the same way for `useCallback`, `useMemo` and `useRef`.

**Keys:** `us` / `ust` → `uel` → `,ca` → `a` → `hook` → `.return` → `useWin`

### Share state with a context

*Several components need the same thing, like the theme or the signed-in user.*

1. Press `,n`, then `a`, create `ThemeContext.tsx` and open it.
2. Insert the `ctx` snippet. It writes the context, a `ThemeProvider` component, and a `useTheme` hook that throws a clear error when it's used outside the provider. The name comes from the file, and typing another one changes it everywhere. Press `Tab` and type the value's type (`dark: boolean`), then `Tab` again for the value itself.
3. Put the cursor on `createContext`, press `,ca` and choose "Add all missing imports".
4. Now wrap your app in the provider. In the root component, press `S`: labels appear around the pieces of code the cursor is in. Press the label of the element you want to wrap, which selects it. Press `c` to cut it out and type in its place, and type `<ThemeProvider>`: the closing `</ThemeProvider>` is added for you, with the cursor between the two. Press `Esc`, then `p` to paste the element back inside. When the file saves, Prettier fixes the indentation.
5. In a component that needs the theme, type `const { dark } = useThe`, then `Tab` and `Enter`: you get `useTheme()` and its import.
6. `gd` on `useTheme` takes you to the context, and `,cr` on `ThemeProvider` shows every place it's used.

**Keys:** `a` → `ctx` → `,ca` → `S` + `c` + `<ThemeProvider>` + `Esc` + `p` → `useThe`

### Load data and handle errors

*Fetch a user from an API, make sure it really is one, then show it.*

1. In `src/api/users.ts`, type `export af`, then `Tab` and `Enter`, to insert the `af` snippet after `export`. Name the function (`loadUser`), press `Tab`, type its parameters (`id: string`), press `Tab` again, and you're in its body.
2. Insert `fetchj`. Type the URL (`` `/api/users/${id}` ``), press `Tab`, and keep the name `data`. The snippet fetches the URL, throws an error if the response isn't OK, and reads the JSON.
3. Check what came back. On the next line, type `!isUser(data).if` and pick `.if` in the menu: it becomes `if (!isUser(data)) {…}`. Inside it, insert `tne` and type your message, which gives ``throw new Error(`…`)``.
4. Below the `if`, type `data.ret` and pick `.return`: it becomes `return data`.
5. Write `isUser` below the function with the `guard` snippet. Type `User` (it's filled in both places), press `Tab`, then write the check, like `typeof value === 'object' && value !== null && 'id' in value`. TypeScript now knows `loadUser` returns a `User`. If `User` needs importing, `,ca` on it does that.
6. To make two requests at once, use `pa`. Type the names for the results (`user, teams`), press `Tab`, then the calls (`loadUser(id), loadTeams(id)`).
7. In the component, insert `ust` (named `user`, typed `User | null`, starting at `null`), then `ue`. In the effect's body, write `loadUser(id).then(setUser)`, press `Tab`, and add `id` as its dependency. Where you'd rather catch the error, `tc` wraps code in `try` / `catch`.

**Keys:** `export af` → `fetchj` → `.if` + `tne` → `.return` → `guard` → `pa` → `ust` + `ue`

## Fix problems

### Clear the problems in a file

*Red and yellow marks after a change, or before you commit.*

1. Press `]d` to go to the next problem and `[d` to the previous one. `,en` / `,ep` do the same and also show the problem's message.
2. Press `,ed` to see the whole message, which helps with TypeScript's long ones.
3. Press `,ca` to see the fixes on offer: add the missing import, remove what's unused, use the name it probably meant, and so on.
4. Press `K` on a name to see its type, to compare with what TypeScript expected.
5. Changed a type, or props that other files pass? Press `,et` to type-check the whole project in the background. The errors go to the quickfix list: `[Q` goes to the first one and `]q` to each next one, whatever file it's in. In a big project that takes a while: the tab says *type-checking*, and if you switch to another app, a notification tells you when it's done.
6. Saving with `:w`, instead of waiting for autosave, also applies ESLint's automatic fixes, such as removing unused imports.

**Keys:** `]d` → `,ed` → `,ca` → `K` → `,et` → `[Q` / `]q` → `:w`

### Find a bug with logs

*Something has the wrong value, and you want to see it.*

1. Type `.log` after any expression to log it: `user.profile.log` becomes `console.log(user.profile)`, and `items.filter(isOpen).log` logs the result of the whole chain.
2. Keep the dev server's output in view. In the Workgroup it runs on the right, and ⌃⌘1 brings it to the front. Without the Workgroup, press `,sv` to split the window and `,tm` to open a terminal in it, and type `dev server`; then `Esc Esc` and `,h` take you back to your code. Server code logs in that terminal, and browser code logs in the browser's console. If an error shows a `file:line`, ⌘-click it to open it.
3. Change the code and look again. Files save themselves, so the dev server reloads without you typing `:w`.
4. Found it? Remove the logs you added. Press `,fg` and search for `console.log`, then press `<M-a>` to mark every match and `Enter` to put them in the quickfix list. `[Q` goes to the first one, `dd` deletes that line, and `]q` goes to the next. Leave the logs that were there before you started.
5. Press `,gv` to review everything your branch changes, and make sure none of your logs are left.

**Keys:** `.log` → ⌃⌘1 (or `,sv` + `,tm`) → ⌘-click → `,fg` → `<M-a>` + `Enter` → `[Q` → `dd` → `]q`

### Find a bug with the debugger

*Logs aren't enough: you want to stop the code and look around.*

1. Put the cursor on the line where the code should stop, and press `,db` to set a breakpoint. `,dB` sets one that only stops when a condition is true, like `user.id === '42'`.
2. Press `,ds` and pick what to run:
   - a script or a TypeScript file: **Node: current file**
   - Next.js: **Next.js: server (dev script)** for route handlers and server components. To debug client components as well, press `,ds` again, choose **Start additional session**, then **Next.js: client in Chrome (:3000)**
   - Vite: start the dev server first (⌃⌘W for the Workgroup, or `,sv`, `,tm` and `dev server`), then pick **Vite: client in Chrome (:5173)**
   - Electron: **Electron: main + renderer**
3. Use the app until it stops at your breakpoint. The debug view shows the variables (press `S`), your watch expressions (press `W`, then `i` to add one) and a REPL (press `R`), where you can run code right where the program stopped.
4. Press `,dn` to step to the next line, `,di` to step into a function call and `,do` to step out of the function. `,dc` runs on to the next breakpoint, and `,dl` shows the value of what's under the cursor.
5. Fixed it? `,de` ends everything and removes the breakpoints. `,dr` runs the same configuration again.

**Keys:** `,db` → `,ds` → `,dn` / `,di` / `,do` → `,dl` → `,dc` → `,de`

## Test

### Write tests as you go

*Tests for new code while you write it, with Vitest or Jest.*

1. Create the test next to `UserCard.tsx`: press `,n` to show the component in the file tree, `a` to add a file, type `UserCard.test.tsx` and press `Enter`, then `Enter` again to open it. Press `,sv` to split the window, and `,ff` to open the component in the other half, so you see both.
2. In the test file, press `,mw` to watch it: its tests run again every time it's saved. Files save when you leave insert mode, so the results keep up as you write. Press `,mw` again, in the test file, to stop watching it. The test list (`,mt`) marks watched files *watching*, and `w` on one stops it too.
3. While the tests run, the status line shows **Tests:** and the file's name. When they finish, the message line at the bottom says how many passed or failed, in green or red. A sign next to each test shows its result, a failure is also marked on the line that failed, and `]d` takes you there.
4. `,mr` runs only the test under the cursor, `,ma` every test in the file, and `,ml` runs the last tests again from any file.
5. `,mo` shows the output of the test under the cursor, including its `console.log`s, and `,ms` opens a summary of every test.
6. In a Jest project, `,fn` copies the test file's name, and `testfile` in a terminal runs it with coverage for the file it tests.
7. In the Workgroup, the Tests pane (⌃⌘2) also runs every test your changes affect, in all files, every time you save. Its status shows *3 failing* or *tests pass*, and ⌘-clicking a failure opens it in Neovim.

**Keys:** `a` → `,sv` + `,ff` → `,mw` → `,mr` / `,ma` → `,mo` → `,ms` → ⌃⌘2

### Fix a failing test

*A test fails, here or in CI.*

1. Press `,ma` to run the file's tests, then `,ms` to open the summary. There, `J` jumps to the next failed test, `o` shows its output and `i` takes you to it. If the failure shows up in the Workgroup's Tests pane, or in CI output in a terminal, ⌘-click its `file:line` instead.
2. In the test file, `]d` takes you to the failing line and shows the assertion's message. `,ed` shows the whole message, with what was expected and what was received.
3. Press `gd` on the function under test to open it, or `,cv` to open it in a split, so the test stays in view.
4. Still not clear? Set a breakpoint with `,db` on a line in the test or in the code, then press `,md` on the test: it runs under the debugger and stops there. The keys from [Find a bug with the debugger](#find-a-bug-with-the-debugger) work from there.
5. After the fix, `,ml` runs that test again, from whichever file you're in.

**Keys:** `,ma` → `,ms` + `J` + `o` → `]d` → `,cv` → `,db` + `,md` → `,ml`

### Run a chosen set of tests

*Some tests from different files, Vitest or Jest and Playwright, without opening each file: for example, the tests around a feature you're changing.*

1. Press `,mt`: the test list opens on the right, with an area for the Vitest or Jest tests and one for each Playwright folder. The status line shows which kinds of tests the project has, like *󰙨 Jest · Playwright*. A long area closes with `Enter` on its title, so the others come into view.
2. Find the tests: press `/` and type a few words of what you're after, like `login error`. The list narrows as you type, to the tests with all of those words in their file path, describe blocks or name, and their files open to show them. `Enter` keeps the filter, and `Esc` removes it again. You can also press `Enter` on a file to see its tests. `?` shows the list's keys.
3. Press `Space` to check a test. On a file, `Space` checks every test in it, and on an area's title, every test in the area. While the list is filtered, that's only the tests on show, so filtering and then `Space` on the title checks every match. To check several lines at once, select them with `V` and `j`, then press `Space`.
4. Press `r` to run what's checked. Vitest and Jest results show in the list, as ✓ or ✗ at the right edge, and in the message line. Playwright tests run in the terminal below your code.
5. Press `i` on a failed test to go to it. After the fix, `,ml` runs the same tests again from whichever file you're in, and so does `r` in the list.
6. To keep a file's tests running while you work, press `w` on it in the list: it's marked *watching*, runs once straight away, and runs again every time you save. Press `w` again to stop watching it.
7. `a` runs every test in the area under the cursor, such as all the Playwright tests, or, while the list is filtered, every test on show in it. `c` unchecks everything, and `q` or `,mt` closes the list. Your checks are still there when you open it again.

**Keys:** `,mt` → `/` → `Space` → `r` → `i` → `,ml` → `w` → `a`

### Run end-to-end tests with Playwright

*Playwright tests are the files that import `@playwright/test`.*

1. `,mr` runs the test under the cursor, and `,ma` every test in the file. They run in a terminal below your code, and the cursor stays in the test file.
2. `,mi` runs the test under the cursor in a browser you can see, paused before its first step. A second window, the Playwright Inspector, controls it: Step over goes one step at a time, Resume runs the rest, and you can try out locators there. If nothing seems to happen, the Inspector is probably hidden behind the browser or behind iTerm2: press F3 (Mission Control) to find it.
3. `,mu` opens Playwright's UI mode, a separate window where you can run any test and watch it step by step on a timeline.
4. `,md` debugs the test under the cursor in Neovim instead, stopping at breakpoints (`,db`) in the test and in the code it uses.
5. `,ml` runs the last tests again. `,j` moves the cursor down to the terminal to read the output, and `,k` back up.

**Keys:** `,mr` / `,ma` → `,mi` → `,mu` → `,md` → `,ml`

## Refactor

### Rename and move things

*A name no longer fits, or a file belongs somewhere else.*

1. Put the cursor on a variable, function, component or type, press `grn`, type the new name and press `Enter`. Every file that uses it changes.
2. To rename a file, press `,n` to show it in the file tree, then `e` to edit its name (the extension is kept), and press `Enter`. Every import of the file changes with it.
3. To move a file, press `x` on it in the tree, then `p` on the folder it belongs in. Its imports change here too.
4. The files whose imports changed are edited, but not saved yet: `:wa` saves them all.
5. Renamed a component's file? Use `grn` on the component and its `Props` interface too, so all the names match.
6. Finally, press `,et` to type-check the whole project and catch anything that didn't follow.

For text that isn't a name in the code, like a string, a CSS class or a test id, see [Change something in many files](#change-something-in-many-files).

**Keys:** `grn` → `,n` → `e` / `x` + `p` → `:wa` → `,et`

## Review and ship

### Review a pull request

*Someone asked for your review.*

1. Run `:!gh pr checkout 123` to switch to the pull request's branch. Files you have open reload.
2. Press `,gv` to open the review in a new tab. It shows what the pull request changes compared with main, with the original version of each file on the left and the new version on the right. If the pull request targets another branch, run `:Review origin/that-branch` instead.
3. `]q` / `[q` go from file to file, and `]c` / `[c` from change to change.
4. The right side is the real file, so `gd`, `K` and `,cr` work: check how a changed function is used elsewhere. `,gb` shows who last changed a line, and why.
5. Run what it touches: `,ma` in a test file, and `,et` to check the types.
6. To comment on some lines, select them with `V` and press `,gy` to copy their GitHub link. Pasted into a comment on GitHub, the link shows the code. `,go` opens the lines on GitHub instead.
7. Press `,gv` to close the review, and run `:!git switch -` to go back to your own branch.

**Keys:** `:!gh pr checkout` → `,gv` → `]q` / `]c` → `gd` / `K` / `,cr` → `,gb` → `,gy` → `,gv`

### Get your branch ready for review

*Before you push and open a pull request.*

1. Press `,gv` to see your branch the way a reviewer will: `]q` goes from file to file and `]c` from change to change. Fix what you find on the right as you go: leftover logs, commented-out code, a rename you missed. `,gv` again closes the review.
2. Press `,et` to type-check the project, and `,ma` in a test file to run its tests.
3. To commit only some of your changes, `]h` goes to the next change, `,gp` previews it, `,gs` stages it and `,gr` throws it away.
4. To commit and push, open a shell beside your code: ⌃⌘4 in the Workgroup, or `,sv` and `,tm` in Neovim. Run `git commit -m "Add user card"` and `git push`, then `gh pr create --web` to open the new pull request's page on GitHub. ⌥⌘← takes you back to Neovim from the Workgroup; from a terminal in Neovim, press `Esc Esc`, then `,h`.
5. Afterwards, `,go` on any line opens it on GitHub.

**Keys:** `,gv` → `]q` / `]c` → `,et` → `]h` + `,gp` + `,gs` → ⌃⌘4 (or `,sv` + `,tm`) → `gh pr create --web`

## Config and docs

### Edit a GitHub Actions workflow

*A change to CI, a new job, a new step.*

1. Press `,ff`, type `ci.yml` and press `<M-h>`. Workflows live in `.github`, a hidden folder, and `<M-h>` includes hidden files.
2. Problems show as you type, and `]d` goes to each one: unknown keys, wrong values, misspelled action inputs (`fetch-depthh`) and contexts that don't exist (`github.shaa`).
3. Inside `${{ }}`, contexts complete: `github.` lists `sha`, `ref`, `event_name` and the rest.
4. `K` on a key explains it. On an action, like `uses: actions/checkout@v5`, it shows what the action does, with a link.
5. To point someone at a step, select it with `V` and press `,gy` to copy its GitHub link.

**Keys:** `,ff` + `<M-h>` → `]d` → `${{ github.` → `K` → `,gy`

### Edit package.json, tsconfig.json and other config

*package.json, tsconfig.json, devcontainer.json, ESLint and Prettier configs, and many more: any file with a published schema.*

1. Press `,ff` and type the file's name.
2. Keys and values complete from the file's schema: in `compilerOptions`, typing `"modu` lists `module`, `moduleResolution` and the rest.
3. `K` on a key explains what it does.
4. Wrong keys and values show as problems, and `]d` goes to each one.

**Keys:** `,ff` → `"modu` → `K` → `]d`

### Write docs in Markdown

*A README, a design doc, notes.*

1. Press `,cs` to list the headings, and pick one to jump to it.
2. For a link, type `[text](#`: the menu lists the file's headings. After `(./` it lists files instead. A link to a file that doesn't exist shows as a problem.
3. `gd` on a link opens the file or jumps to the heading, and `<C-o>` takes you back. `gx` opens a web link in your browser.
4. `grn` on a heading renames it, along with the links to it in the file.
5. Saving formats the file with Prettier, tables included.
6. `,gy` copies the GitHub link to the line or the selected lines, to share a section.

**Keys:** `,cs` → `(#` → `gd` / `<C-o>` → `grn` → `,gy`

## When you need it

### Ask AI about some code

*All AI is off until you start it. Chat and the agent only run while they're open.*

1. Select the code, with `V` and a motion or with `S` and a label, then press `,ac`: a chat opens with that code in it. Type your question and press `Enter` to send it. `<C-s>` sends it while you're still in insert mode.
2. When the chat proposes changes to your file, `gv` shows them as a diff, `g2` accepts them and `g3` rejects them. `gy` copies the last code block from the answer, and `<C-c>` closes the chat.
3. Writing something repetitive? `,al` turns on ghost text: grey suggestions appear as you type. `Tab` accepts one when the completion menu is closed, and `<M-]>` shows the next. `,al` again turns it off.
4. For a bigger job, `,aa` opens the agent (Copilot CLI) in a split beside your code. `,af` sends it the current file, and `,ap` offers ready-made prompts: explain, fix, write tests, review and more.
5. If something doesn't answer, `:AIStatus` shows what's on and what's missing.

**Keys:** `V` + `,ac` → `g2` / `g3` → `,al` + `Tab` → `,aa` → `,af`

### Get back something you changed

*An edit went wrong, or you want an earlier version back.*

1. `u` undoes and `<C-r>` redoes, even after you've closed and reopened the file.
2. `,u` opens the undo history as a tree. Move through it and the file changes with you; stop at the version you want, and press `,u` again to close the tree.
3. To get back what git has, `]h` goes to a change, `,gp` shows the old version and `,gr` puts it back.
4. `,gd` shows the whole file next to the version git has, side by side.

**Keys:** `u` / `<C-r>` → `,u` → `]h` + `,gp` + `,gr` → `,gd`

### When something stops working

*Completion is gone, errors don't update, or something just seems off.*

1. If completion, `gd` or the problems stop working in a file, run `:lsp restart` to restart its language servers.
2. Still not right? `:checkhealth vim.lsp` shows which language servers are running for the file, and why one isn't.
3. If anything else seems odd, `:restart` restarts Neovim with the same files open, and `:checkhealth` checks the whole setup.
4. If the AI doesn't answer, run `:AIStatus`.
5. If ⌘-click, the Workgroup or the Dotfiles profile is missing in iTerm2, run `./setup.sh` in the dotfiles folder. It lists what's left to do, such as making Dotfiles the default profile or restarting iTerm2.
6. Every week or so, run `./setup.sh` in the dotfiles folder to bring everything up to date.

**Keys:** `:lsp restart` → `:checkhealth vim.lsp` → `:restart` → `./setup.sh`
