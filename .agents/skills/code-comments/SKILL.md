---
name: code-comments
description: Use when writing, reviewing or cleaning comments in this Neovim config (Lua under lua/, init.lua, the rules CLI under tools/). Defines when a comment earns its place, what it may say, what it must never say, how long it may be, and the language it is written in. Also the playbook for a comment-cleaning sweep over many files.
metadata:
  version: '1.0-nvim'
  scope: [general]
  auto_invoke: 'When adding, editing or removing code comments, or when asked to clean comments'
---

# Code comments

Adapted from the `code-comments` skill of the `mio` repo. Two changes for this repo, both from the
owner's global instructions: comments are written in **neutral Spanish** (no voseo), and the long
technical *why* lives in `docs/decisions.md`, with a one-line pointer from the code.

The code says **what** it does and **how**. A comment is only for what the code cannot say: **why** it
is this way, and what a reader would otherwise get wrong. Every comment costs reading time and goes
stale when the code changes and the comment does not. A wrong comment is worse than none.

## The test every comment must pass

Read the comment, then cover it and read only the code. Ask:

1. **Would a competent reader, new to this file, miss something important without it?** If not, delete it.
2. **Does it say why, or warn about something the code cannot show?** If it only restates what the
   code does, delete it.
3. **Will it still be true after the next unrelated change?** If it describes history, a process or a
   moment in time, delete it or rewrite it in the present tense.
4. **Is it the shortest form that carries the point?** If not, cut it.

## Keep (and write) a comment for

- **Intent behind a non-obvious choice.** Why this approach and not the obvious one.
  *"Repinta sin re-escanear: al cerrar un split el buffer sigue cargado y neo-tree no se entera."*
- **A constraint the code cannot express.** Ordering (`init` vs `config` in a lazy spec), units
  (milliseconds), an event that fires before the window is gone.
- **Code that looks wrong or redundant but is not**, so nobody "simplifies" it away.
- **A workaround or a patch of a plugin internal.** Name the plugin and what it works around, and
  link the upstream issue when there is one. Say how to know when it can be removed.
- **A pcall that swallows an error on purpose**: why doing nothing is correct there.
- **A source**: the `:help` tag, the plugin doc or the upstream issue.
- **A known limitation**, as `TODO: what is missing` with enough context to act on it.

## Delete (or never write) a comment that

- **Restates the code or the name.** `-- abre el árbol` over `open_tree()`.
- **Narrates the steps of a function.** `-- 1. validar`, `-- 2. construir`.
- **Tells history or process.** "Antes…", "ahora…", "se cambió a…", "ESE era el bug", dates.
  History lives in git and in `docs/decisions.md`.
- **Names the tooling behind a change.** No linter rule ids, no "audit", "review", "quality pass",
  "AI", "Claude".
- **Is commented-out code.** Delete it; git keeps it.
- **Decorates** beyond a single section header (`-- ── Sección ──`). One header per section is this
  repo's convention for long files; boxes and closing-brace comments are not.
- **Duplicates documentation that lives elsewhere.** Behavior rules belong in `docs/business-rules/`
  (through `bun run rules:add`), technical decisions in `docs/decisions.md`. Point there in one line.

## Never put in a comment

Secrets, tokens, personal data, internal hostnames or IPs, machine-specific paths other than the
standard Neovim ones (`stdpath(...)`), opinions about people.

## Length and form

- **One to three lines is the default.** More than five lines means the content belongs in
  `docs/decisions.md`, with a one-line pointer: `-- Por qué: docs/decisions.md#d-07`.
- **No line wider than 100 columns.**
- **Present tense, neutral Spanish**, no voseo (*abre*, not *abrís*). Identifiers stay as they are.
- `---` (LuaCATS) documents a function or module field when the signature does not finish saying
  it (`--- @param`, `--- @return` only when they add information). `--` explains a detail inside a body.
- A comment sits directly above what it explains, or at the end of a short line.

## Cleaning sweep (many files)

- **Comments only.** Do not change behavior, names, strings shown to the user, or formatting of code.
- **Edit with the Edit tool, file by file.** Never with scripts, `sed`, or bulk replacement.
- **Out of scope:** `lua/material_folders.lua` (generated), `lazy-lock.json`, YAML rules, Markdown docs.
- Walk every comment of every file in the slice through the test above: delete, rewrite or keep.
  When the why is long, move it to `docs/decisions.md` and leave the pointer.
- After the slice, start Neovim headless and check `:messages` is empty
  (`nvim --headless +'lua vim.defer_fn(function() print(vim.api.nvim_exec2("messages",{output=true}).output) vim.cmd("qa!") end, 1500)'`).
- Report: files touched, comments deleted / rewritten / kept, decisions moved to the doc.

## Sources

- Ellen Spertus, *Best practices for writing code comments*, Stack Overflow Blog (2021).
- Jeff Atwood, *Code Tells You How, Comments Tell You Why*, Coding Horror.
- John Ousterhout, *A Philosophy of Software Design*: comments describe what is not obvious from the code.
- MITRE CWE-615, *Inclusion of Sensitive Information in Source Code Comments*.
