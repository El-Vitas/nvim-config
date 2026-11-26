# nvim-config

My Neovim setup: a fast editor for reviewing and writing code, with a built-in code review mode, a
file tree that shows what changed against any commit, and Markdown that reads like a document.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/El-Vitas/nvim-config/main/install.sh | bash
```

The installer checks the requirements, moves any existing `~/.config/nvim` aside (it never deletes
it), clones this repo, installs the folder-icon font and downloads the plugins. Options:

```bash
curl -fsSL https://raw.githubusercontent.com/El-Vitas/nvim-config/main/install.sh | bash -s -- --no-fonts
```

Prefer to do it by hand? `git clone https://github.com/El-Vitas/nvim-config ~/.config/nvim` and open
`nvim`; lazy.nvim installs everything on the first start.

### Requirements

| Needed | For |
|---|---|
| Neovim 0.12+ and git | Everything |
| A [Nerd Font](https://www.nerdfonts.com/font-downloads) in the terminal | Icons (the config expects CaskaydiaCove Nerd Font) |
| ripgrep | Grep across the project |
| make and a C compiler | The fast fuzzy sorter (fzf-native) |
| tree-sitter CLI | Compiling syntax parsers |
| Node.js | The TypeScript, ESLint and Tailwind language servers |

Only Neovim and git are required; without the rest, the matching feature is disabled and the editor
still starts cleanly.

## What it does

- **Code review inside the editor.** [review-mode.nvim](https://github.com/El-Vitas/review-mode.nvim)
  adds comments on lines, inline and side-by-side diffs against HEAD or any commit, and exports the
  comments ready to paste into an AI agent.
- **A file tree that knows git.** `<space>s` toggles between changed files and the whole project;
  folders get colored Material icons when the font is installed.
- **Markdown that reads well.** Rendered headings, tables as a grid and a preview that scrolls with
  the file (`<space>M`).
- **Fast.** Plugins load when first used, and opening a file never waits for treesitter or git. The
  measurements behind each choice are in `docs/decisions.md`.

Press `<space>?` inside Neovim for the full cheatsheet.

## Layout

| Path | What is there |
|---|---|
| `init.lua` | Bootstraps lazy.nvim and loads the modules |
| `lua/config/` | Options, the cheatsheet, the buffer limit, binary files, Markdown grid and preview |
| `lua/plugins/` | One lazy.nvim spec per plugin or group |
| `fonts/` | The folder-icon font and its fontconfig rule (see `fonts/NOTICE.md`) |
| `tests/` | End-to-end tests with the real keys (`tests/run.sh`) |
| `docs/` | Behavior rules and technical decisions |

## License

MIT. The folder icons come from Material Icon Theme (MIT); see `fonts/NOTICE.md`.
