# Technical decisions of the config

Why each part of the config is built the way it is. What the editor **must do** is in [`business-rules/`](business-rules/README.md); here goes **how** it is achieved and what was discarded. Each decision has a stable id (`D-NN`) that the code comments point to.

The measurements come from Neovim without a UI (`--headless`) on the FastCase repo: 1,402 versioned files, 38,034 folders and an ignored `node_modules` with 571,230 files. The measurement scripts are run with `nvim --headless` and measure how long each action blocks (the time until the key returns control). The real UI adds the terminal drawing, a few milliseconds.

## Result of the optimization of 2026-10-28

| Action | Before | After |
|---|---|---|
| `<leader>s` (open the changes tree) | 4,481 ms | 14–20 ms |
| `<leader>e` (open the file tree) | 41 ms | 6–11 ms |
| Switch buffer | 41 ms | 0.5–0.6 ms |
| Open a JS/TS project (LSP file watching) | 4,600 ms blocked | delegated to `inotifywait` |
| Open a file for the first time in the session (D-21) | 270–490 ms | 12–35 ms |
| Open a file when coming back from the browser (D-21) | up to 708 ms | 3–10 ms |
| Startup until the first screen | ~265 ms | ~265 ms |

Startup did not change. It is dominated by opening the first file (the TypeScript highlight queries cost ~70 ms and review-mode loads its modules). Moving plugins to lazy loading saved little compared with that.

Lua was not the problem, so rewriting parts in Rust would not have helped. All the causes were unnecessary work done synchronously: asking git for half a million lines that nobody displayed, saving the session on every buffer leave, walking 38,000 folders on the UI thread.

---

## D-01 · The changes tree does not ask git for ignored files

`lua/plugins/neotree.lua`, function `skip_ignored_in_changes`.

The neo-tree changes view (`git_status`) runs `git status --untracked-files=all --ignored=traditional` synchronously. With that combination git lists **every** ignored file. In FastCase that is 571,230 lines that neo-tree parses in Lua, and `<leader>s` blocked for 4.5 s. That view then discards the ignored state (`sources/git_status/lib/items.lua`, filter `status ~= "!"`), so the work was useless.

The config subscribes to neo-tree's public `before_git_status` event and changes `--ignored=traditional` to `--ignored=no`, only in the call that carries `--untracked-files=all` (the one from the changes view). The file tree uses other calls and keeps hiding the ignored files.

- **Measured:** 4,481 ms → 37 ms in the first experiment; 14–20 ms with everything else applied.
- **Discarded:** git's `core.fsmonitor` and `core.untrackedCache`. They speed up the disk walk, but the cost was in the volume of text returned, not in the walk.
- **Fragility:** it depends on neo-tree continuing to emit `before_git_status` with `status_args`. If it stops doing so, `<leader>s` becomes slow again, but nothing breaks.

## D-02 · The session is saved after one second of calm, not on every BufLeave

`lua/plugins/persistence.lua`.

The automatic save ran `persistence.save()` on every `BufLeave` of a file, so that the session stayed up to date even if the terminal was closed abruptly. Each save is a `:mksession` plus a synchronous `git branch --show-current`, between 25 and 38 ms. `BufLeave` fires when moving to the tree, when opening Telescope and when switching buffers, so all those actions carried that cost.

Now `BufEnter` and `BufWritePost` restart a 1 s timer and a single save happens when there is calm. `FocusLost` saves immediately and persistence's own `VimLeavePre` saves on exit. The save respects `persistence.active()`; before, it kept saving after `<leader>qd`.

- **Measured:** switching buffers went from 41 to 2.6 ms with this alone.
- **Accepted cost:** if the terminal dies, the session can be up to 1 s behind.

## D-03 · The ● of an open file is repainted with `renderer.redraw`

`lua/plugins/neotree.lua`, function `redraw_tree`.

The config had a deferred `Neotree refresh` on `BufWinEnter`/`WinClosed`/`BufDelete` to update the ●. `refresh` is not a valid argument of `:Neotree` and it failed with `Invalid argument: refresh`, hidden by a `pcall`. Before failing, the parser ran `git rev-parse --verify refresh` synchronously. It never refreshed anything.

neo-tree repaints on its own only when a buffer is added or deleted. When a split is closed the buffer stays loaded, and the ● stayed stuck. The config calls `renderer.redraw(state)` 100 ms after `BufWinEnter` or `WinClosed`, with a single reused timer. `redraw` re-evaluates the components of the nodes that already exist, without scanning the disk or calling git. Floating windows do not trigger the repaint, because they do not count as "open in a pane" and every Telescope preview repainted the tree.

The ● queries a set of visible files that is built once per render (`before_render`). Before, it walked all the buffers for every file in the tree: 5.3 ms with 1,400 nodes and 60 buffers, versus 0.13 ms for the set. The background of the current file is located by node id (NuiTree returns its line) instead of walking all the lines.

- **Verified:** the ● of a closed split disappears in under 300 ms; switching buffers stays at 0.6 ms.

## D-04 · The ignored-files check of `hidden.lua` is asynchronous

`lua/config/hidden.lua`, function `ensure_filter`.

On the first render, neo-tree has not yet marked the ignored files and shows them. `hidden.lua` verifies the result against git (`git check-ignore --stdin` with the visible paths) and navigates again if any remain, with a cap of 6 attempts. The check waited for git with `:wait()` after every render, including renders of the changes tree, which has no ignored files to filter.

Now it runs with `vim.system` and a callback, only after file tree renders, and it does not launch a new one while another is still in progress.

- **Measured:** in FastCase its weight was low (within the noise). It was changed anyway because waiting for an external process on every render is a risk that grows with the repo.

## D-05 · LSP file watching is done by `inotifywait`

No changes in the config. It requires the system package `inotify-tools` (`sudo dnf install inotify-tools`).

When vtsls starts, it asks to watch the project files (`workspace/didChangeWatchedFiles`). Neovim chooses how to do it in `runtime/lua/vim/lsp/_watchfiles.lua`. On Linux it uses `inotifywait` if it exists, and otherwise it falls back to `watchdirs`, which walks every folder in Lua and creates one watcher per folder, on the UI thread.

- **Measured:** `watchdirs` on FastCase blocked for 4.6 s (38,034 folders). It happened when opening any JS/TS file, and explains a large part of the slowness "on open".
- **Discarded:** turning off `didChangeWatchedFiles` in the client capabilities. It works, but the server loses the notices about files created or deleted outside the editor.
- **System limit:** `fs.inotify.max_user_watches` is 133,052, plenty for 38,000 folders.

## D-06 · Lazy loading of what is not used at startup

| Plugin | Before | Now |
|---|---|---|
| telescope | `lazy = false` with no documented reason | `cmd = "Telescope"` + its keymaps |
| nvim-cmp | at startup | `event = "InsertEnter"` |
| harpoon | at startup (keymaps defined in `config`) | `keys` |
| nvim-lspconfig, mason, mason-lspconfig | at startup | `event = { "BufReadPre", "BufNewFile" }`, mason as a dependency so its PATH is ready before the first server. mason-lspconfig also carries `lazy = true`: a spec without a trigger is a root and lazy loads it at startup even if it is a dependency of another (22 ms) |
| nvim-window-picker | at startup | `lazy = true`; neo-tree requires it with `require` when `w` is used |
| `material_folders` (4,600 lines, ~9 ms) | when reading the neo-tree spec | on the first render of a folder |
| nvim-lsp-file-operations | only when pressing `<leader>e` | `event = "VeryLazy"` |

neo-tree stays with `lazy = false` on purpose, because opening `nvim .` (`hijack_netrw_behavior`) and restoring the tree need it loaded before the first buffer.

lsp-file-operations hosted the `<leader>e`/`<leader>E` keymaps and was only loaded when they were pressed. If the tree was opened with `<leader>s` or when restoring the session, moving a file in the tree did not update the imports.

## D-07 · `vim.snippet` instead of LuaSnip

LuaSnip and cmp_luasnip had no snippets of their own loaded. They only expanded the snippets sent by the language server, and Neovim 0.12 does that with `vim.snippet.expand`. Both plugins were removed; loading LuaSnip cost 12 ms at startup.

## D-08 · The tree keymaps live in the neo-tree spec

`<leader>e` and `<leader>E` went from being anonymous functions in the lsp-file-operations spec to local functions (`toggle_tree`, `reveal_in_tree`) registered in the neo-tree spec. They reuse `find_neotree_win()` instead of repeating its window walk.

Both open the tree through `nt_exec`, which delegates to `require("review").neotree_exec`. That function injects review's base when the mode is changes. Opening with the bare `:Neotree` command ignored the base and the changes tree went back to plain `git status`.

## D-09 · Telescope with `telescope-fzf-native`

Telescope's default sorter is written in Lua. `telescope-fzf-native` uses fzf's algorithm compiled in C, and Telescope's own documentation recommends it. It is compiled with `make` on install; if the build fails, `pcall(load_extension)` leaves Telescope with the Lua sorter.

- **Not measured:** the automatic measurement of filtering was not reliable and is not used as evidence. It was adopted on upstream's recommendation.

## D-10 · treesitter on the `main` branch

The config called `require("nvim-treesitter.configs")`, which does not exist in the installed `main` branch. The `pcall` hid it, so `ensure_installed` never ran: the `html` and `css` parsers were missing, and treesitter indentation was never active. Now `get_installed()` is queried and only what is missing is installed, asynchronously.

treesitter indentation stays off. In `main` it is experimental, and turning it on would change how the editor indents.

## D-11 · Copilot is configured in `init`

`plugin/copilot.vim` maps `<Tab>` at load time if `g:copilot_no_tab_map` does not exist yet. The config defined that variable in `config`, which runs after the plugin loads, and a global Copilot `<Tab>` was left behind. It worked by chance, because the mapping expression checks the variable on every keypress. The variables moved to `init`. `build = ":Copilot setup"` was removed, since it is an interactive authentication and not a build step. On a new machine, `:Copilot setup` is run once by hand.

## D-12 · Neovim 0.12.6 and up-to-date plugins, with nvim-scrollbar pinned to v1

Neovim went from 0.12.1 to 0.12.6 (checksum verified against the one published on GitHub). In between is the fix for CVE-2026-11487, command execution via `vim.secure.read()`, fixed in 0.12.3. 0.12.1 was backed up at `/opt/nvim-linux-x86_64.0.12.1.bak`.

15 plugins were updated. Before accepting the update, it was checked that the internals the config uses still have the same shape:

- **gitsigns:** `Repo:file_info(file, revision)` and `object_missing` (rename patch).
- **neo-tree:** `git.status`, `worktrees[...].status_diff`, `before_git_status`, `fs._navigate_internal`, `renderer.get_expanded_nodes`, `force_open_folders`.
- **render-markdown:** `core.preview.get` and `.buffers`, `core.manager.attached`, `state.get`. Since D-22 the preview is our own and only `state.get` remains.

nvim-scrollbar warned on every startup that on 2026-11-16 its `main` moves to v2, which rejects the v1 options and the handlers API that review-mode uses for its marks. `branch = "v1"` was pinned, which points to the same commit as before the update. Migrating to v2 is pending ([issue #121](https://github.com/petertriho/nvim-scrollbar/issues/121)).

## D-13 · One reused timer instead of `vim.defer_fn` + `stop()`

`vim.defer_fn` creates a timer that closes itself when it fires. If it is stopped with `stop()` before it fires, it is never closed and the handle stays open. `mdtable.lua` did that on every burst of markdown events (every edit, every resize). The pattern of the config is one `vim.uv.new_timer()` per module, with `stop()` and `start()` on each event. It is used by `mdtable.lua`, `persistence.lua` and `neotree.lua`.

## D-14 · Everything lives in `~/Dev/nvim`

| Folder | What it is | Git |
|---|---|---|
| `config/` | This config. `~/.config/nvim` is a symlink to it | `El-Vitas/nvim-config` |
| `review-mode/` | The review plugin. `lua/plugins/review.lua` loads it with `dev = true`: this local copy when it exists, GitHub otherwise | `El-Vitas/review-mode.nvim` |
| `material-font/` | Generator of the folder icon font. It includes `out/MaterialFolders.ttf` and the fontconfig rule; both are copied to `config/fonts/` for `install.sh` | own repo, no remote |

## D-15 · Rules documentation with the `mio` CLI

The behavior rules use the same registry as the `mio` repo (`tools/rules-cli`, an unchanged copy of `packages/rules-cli`). This way they are queried with the same commands and the same skill. Neovim does not read `package.json` or `node_modules/`, because it only searches `lua/`, `plugin/` and the other folders of the runtimepath.

## D-16 · gitsigns patch for files renamed against a base

`lua/plugins/gitsigns.lua`.

With an explicit base (`change_base <commit>`, which review-mode sets when choosing a base), a renamed file was painted entirely as added. `Repo:ls_tree` looks up the rename with `self:diff_rename_status(revision, true)[path]`: that map has repo-relative keys and `path` arrives absolute, so it never matches. Verified in gitsigns `d4854fa` (`lua/gitsigns/git/repo.lua:757`).

The patch wraps `Repo.file_info` and only acts when gitsigns has already flagged `object_missing`. It asks `review.core.git.rename_source` whether the file is the destination of a rename against the base and, if it is, returns the blob of the old path. Everything else is left to gitsigns.

- **When to delete it:** if gitsigns starts looking up the rename with the relative path, `object_missing` stops arriving in that case and the patch does not fire. It can be deleted as is.
- **If gitsigns changes the API:** without `Repo.file_info`, the config warns at startup instead of failing silently.
- **Verified:** a rename against the base shows 0 added lines (before, the whole file).

## D-17 · Findings of the quality review of 2026-10-28

The review ran `lua-language-server --check`, `jscpd` and four reviewers in parallel over the config and review-mode. The full reports were left outside the repo. What was fixed in the config:

| Problem | Effect | Fix |
|---|---|---|
| `return true` in the `BufReadCmd` of `open.lua` | In Lua, a truthy value deletes the autocmd (`:h nvim_create_autocmd`). The second binary of the session opened as editable text and a `:w` modified it | No return |
| `++bin` read from `'binary'` inside `BufReadCmd` | `:OpenRaw` on a file that was not open showed the help screen again in a loop | `v:cmdarg` is read and `'binary'` is set before reading |
| Binary patterns in lowercase | `FOTO.PNG` opened as text | Patterns in both cases |
| persistence's deferred save without a filter | A `git commit` with `EDITOR=nvim` overwrote the session with `COMMIT_EDITMSG` | Same filter as persistence on exit (`gitcommit`, `gitrebase`, `jj`) |
| Copilot in all buffers | The contents of `.env` and keys went out to GitHub | `copilot_filetypes` and `b:copilot_enabled = false` by file name |
| lua_ls without the Neovim API | 9 `undefined-global` per file of this config, no `vim.*` completion | nvim-lspconfig recipe, only for Neovim config or plugin folders |
| cmp capabilities only on vtsls | eslint, tailwind and lua_ls did not receive cmp's | `vim.lsp.config("*", { capabilities })` |
| Inlay hint trimming by byte | It cut UTF-8 characters in half | `strchars` / `strcharpart` |
| mdtable turned wrap off in all markdown | `<leader>w` had no effect in files without tables | Wrap is touched only if there are tables |
| mdtable ignored raw mode | `<leader>m` left the grid drawn | It respects render-markdown's `state.enabled` and the toggle refreshes it |
| `ignore_ft` and `pcall` in the treesitter startup | Dead entries and real errors hidden | Only file buffers and only with a parser |
| Nonexistent `c.blue` in lualine | The "md split" indicator came out gray | Color defined |
| Options that do not exist or are the default (cmp's `matching`, persistence's `options`) | Noise that does nothing | Deleted |

In review-mode, the fixes and their reasons are in `review-mode/docs/decisions.md` (B7 to B15 and D24 to D26).

What remains pending, with the reason:

- **mason-lspconfig's `automatic_enable`** enables every server installed with mason (pyright is enabled even though the config does not mention it). Deciding which servers start is up to the owner.
- **review-mode's `sidebar._refresh`** does a `Neotree refresh` on every comment change, for a 💬 marker that no renderer draws. With D-01 that refresh costs about 18 ms; removing it or finishing the marker is a decision about the feature.
- **The comments gutter** draws with the saved `lnum` while the highlight follows the extmark: when inserting lines without saving, the bracket stays one line off until saved. Fixing it touches the function that is evaluated for every line on every redraw.

## D-18 · A shared palette

`lua/config/palette.lua` holds the 13 colors that have to match across the theme, the statusline, the tree, markdown and the cheatsheet (about 60 uses of repeated hex literals across five files). Single-use colors (those of each folder type, the backgrounds of the markdown headings) stay in their file.

- **Verified:** the dump of the 2,586 highlight groups and of the lualine theme is identical before and after. The only difference, `DevIconLogos`/`DevIconASM`, is nvim-web-devicons noise: two extensions share a name with different colors and whichever is walked first wins.

## D-19 · Option cleanup and buffer-close semantics

- Options equal to their plugin's default value were deleted (verified in each one's code): nvim-ts-autotag, treesitter-context, which-key (`delay`), nvim-scrollbar, onedarkpro (`terminal_colors`, `highlight_inactive_windows`), nvim-web-devicons (`color_icons`). Only those that change something remain, with their reason.
- which-key declares its groups in `opts.spec` instead of a custom `config`.
- The cheatsheet lists the LSP keymaps that Neovim 0.12 ships (`grn`, `grr`, `gri`, `grt`, `gra`, `gO`) and no longer has the fallback for versions without `footer` in floating windows.
- `buffers.lua` closes with `:bdelete` and not with `nvim_buf_delete` (which is `:bwipeout`): review's changes quickfix, the marks and the jumplist keep pointing to the file, and review-mode receives the `BufDelete` with which it frees its caches.

## D-20 · gitsigns blame is computed against HEAD even when there is a base

`lua/plugins/gitsigns.lua`.

Reported on 2026-10-28 in FastCase with base `efe1a41`. `pagination.constants.ts` is committed in `191787f`, but the blame of the line said "Not Committed Yet". Two things in gitsigns `d4854fa` cause it:

1. With an explicit base, `CacheEntry:run_blame` passes the base to `git blame`. If the file does not exist in the base, `run_blame` does not even call git and marks everything as not committed (`lua/gitsigns/git/blame.lua:229`).
2. `CacheEntry:get_blame` skips the blame on lines that fall inside a hunk and marks them "Not Committed Yet" (`lua/gitsigns/cache.lua:231`). With base HEAD that is correct, because a hunk is an uncommitted change. With a commit base, everything changed since the base is a hunk, even if it is committed.

The base is for comparing (signs, views). Blame has to say who wrote the line, and that does not depend on what it is compared against. That is why the two patches act only when the base is a commit. `run_blame` runs against HEAD if the file exists in HEAD, and `get_blame` runs the real blame instead of the shortcut. What is truly not committed is marked by git itself.

- **Verified:** in FastCase, line 3 of `pagination.constants.ts` shows `191787f` and a line edited without saving still shows "Not Committed Yet".
- **Cost:** with a commit base, resting the cursor on a changed line runs a `git blame -L` of that line, just like on any unchanged line.
- **If gitsigns changes the API:** without `run_blame` or `CacheEntry.get_blame`, the config warns at startup.
- **File path:** the patch takes it from the buffer and not from `obj.file`. On a rename, gitsigns builds `obj.file` with the base path that D-16 returns (`lua/gitsigns/git.lua:345`), and that path does not exist in HEAD. With `obj.file`, `data-table-pagination.tsx` (renamed from `apps/web`) gave "Not Committed Yet"; now it gives `191787f`, same as `git blame`.
- **Without blocking:** both patches query git with `repo:command`, which runs inside gitsigns' coroutine. The first version used `vim.system():wait()` and froze the UI for between 4 and 68 ms.

## D-21 · Opening a file does not wait for treesitter or git

`lua/plugins/treesitter.lua` and, in review-mode, `lua/review/core/git.lua` (B22).

Reported on 2026-10-28: "when switching between files it sometimes takes very long". It was measured in FastCase with base `efe1a41`, opening five files for the first time, going back to them and coming back from the browser (`FocusGained`). Going back to an already open file cost 1–7 ms. The slow part was the first time, and there were three causes.

1. **Compiling the treesitter queries.** Neovim compiles a language's highlight and injection query the first time it uses it in the session, in C and blocking: TypeScript 155 ms, TSX 180 ms, JavaScript 75 ms. The LuaJIT profiler attributed 74% of the open to `vim/treesitter/query.lua:375`. Now they are compiled ahead of time, one query per step (80 ms at most) with a timer that starts 1.5 s after the config loads and that every keypress postpones by one second. Verified with real keys every 100 ms for 4 s: it compiled nothing while typing, and finished 3 s after stopping.
2. **review's renames against the base.** Detecting them costs git ~115 ms per `git diff -M` in that repo, and review ran two of them synchronously the first time a file that does not exist in the base was opened. It also threw away the result on every `FocusGained`, so coming back from the browser paid again: up to 708 ms. Detail and fix in review-mode B22.
3. **The blame patch** (D-20) blocked with `vim.system():wait()`. It moved to `repo:command`.

| First open in the session | Before | After |
|---|---|---|
| `app.module.ts` (first TypeScript) | 291–368 ms | 29–43 ms |
| `data-table-pagination.tsx` (first TSX) | 262–277 ms | 17–22 ms |
| `pagination.constants.ts` (does not exist in the base) | 319–493 ms | 12–25 ms |
| The same file when coming back from the browser | 272–708 ms | 8–10 ms |

One case remains uncovered. If in the first second and a half after startup a file type is opened whose query is not yet compiled, the compilation is paid as before. Starting Neovim by opening a file is not in that case, because startup already includes its query.

Compiling everything at startup was discarded: it adds up to ~530 ms blocked before the first screen. Neovim also does not save compiled queries to disk, so there is no way to avoid compiling them once per session.

## D-22 · Own markdown preview

`lua/config/mdpreview.lua`, hooked to `<leader>M` in `lua/plugins/markdown.lua`. Test: `tests/mdpreview.lua`, which is run with `tests/run.sh`.

Reported on 2026-10-28: the two columns of the preview did not move together, and it had to be checked what happened when combining it with review's views. Reproducing it with render-markdown's preview (`core/preview.lua`, commit `8e87953`) showed four failures:

1. It only copies the cursor from the source to the preview, on `CursorMoved`. `<C-e>` left the source on line 6 and the preview on line 1, and moving in the preview did not move the source.
2. It pins the source window when opening and attaches the events to the buffer. When another file was opened in that window, the preview kept showing the previous one.
3. It knows nothing about review. `<leader>rs` with the preview open left three columns (base, file and preview), and `<leader>M` with review's split did too.
4. The table grid (`config.mdtable`) attaches to `*.md` files, and the preview buffer has no name, so tables came out raw. The config's treesitter autocmd only starts on file buffers, so the code blocks came out without colors.

Fixing that from outside required patching several private render-markdown functions, so the preview became our own. It follows the same idea as mdtable, which already replaces the table renderer. From render-markdown only the public API `set_buf` is used, plus `state.get` to read whether a buffer is shown raw.

- **Scrolling:** each pane takes the other to the same top line and cursor line with `winrestview`. `WinScrolled` covers `<C-e>`, `<C-d>`, the wheel and jumps. `CursorMoved` covers what does not scroll. Which pane moved comes from `v:event` and not from focus, because the wheel scrolls the window under the mouse. A flag cuts the bounce.
- **`scrollbind` was discarded.** review's diff mode also uses it, and three windows with `scrollbind` drag each other. It is also a window option that is saved per buffer, the same problem as review-mode B20's pinned diff.
- **Content:** the source's `TextChanged` and `TextChangedI` copy the lines to the pane and fire `TextChanged` on it so render-markdown redraws. The pane's grid is drawn with `mdtable.render` and treesitter is started by hand.
- **Lifecycle:** the pane has `winfixbuf`, like the base column of review's split, and it is closed without `DiffUpdated` because of review-mode B19's SIGSEGV. If the source is closed and the pane is left alone in its tab, the same criterion as neo-tree's autoclose applies. On close, the source recovers the mode (md or raw) it had.
- **With review:** the preview listens to `view:changed` and closes when review goes to split. Opening the preview with review in split switches review to normal. The inline view coexists with the preview, because it is drawn over the raw file.

**Verified:** `tests/run.sh` runs 29 checks with real keys, three times in a row with no failures. With an expectation changed on purpose, the script reports the failure and exits with code 1.
