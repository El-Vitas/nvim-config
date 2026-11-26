---
name: git-flow
description: Git workflow for commits, branches, and PRs in this Neovim config repo. Use when creating commits, branches, or PRs. Covers commit message format, branch naming, staging rules and PR description format (manual or via gh CLI).
metadata:
  version: '2.0-nvim'
  scope: [general]
  auto_invoke: 'When creating commits, branches, or organizing code changes'
---

# Git Flow

Adapted from the `git-flow` skill of the `mio` repo. Read it before running `git commit`,
`git checkout -b` or `gh pr create`.

# Critical rules

## Push only when asked

The agent pushes and opens PRs only when the owner asks for it. Otherwise it creates branches,
stages files and writes commits, and the owner pushes.

## NEVER stage everything

Always `git add <specific files>`. Never `git add .`, `git add -A` or `git add <dir>`.

## Commit only when asked

The agent commits only when the owner asks for it in this session. Approval for one commit does not
extend to the next.

## No co-author trailers

Commits are authored only by the owner. No `Co-Authored-By` lines, no "Generated with" footers.

## Branches

Git flow, always. `main` is what is released and `develop` is where work comes together. Every
change starts on a branch from `develop`:

```
<type>/<short-description>      # feat/review-base-selector, fix/neotree-marker
```

Types: `feature/` or `feat/`, `fix/`, `perf/`, `chore/`, `docs/`, `refactor/`, `test/`. Kebab-case,
one logical change per branch. The branch merges into `develop` through a PR, and `develop` reaches
`main` through another PR. Nothing is committed straight to `main` or `develop`.

# Commit message format

```
<type>(<scope>): <subject>
```

| Type | Use |
|---|---|
| `feat` | New behavior in the editor |
| `fix` | Bug fix |
| `perf` | Faster, same behavior |
| `refactor` | Same behavior, cleaner code |
| `docs` | Only docs, rules or skills |
| `chore` | Plugin updates, lockfile, tooling |
| `style` | Formatting only |
| `test` | Tests only |

**Scope**: the area touched — `neotree`, `lsp`, `cmp`, `session`, `telescope`, `markdown`, `review`,
`treesitter`, `ui`, `keymaps`, `rules`, `docs`.

**Subject**: imperative, lowercase first letter, no final period, max 72 characters, no vague words
("changes", "fixes", "update"). Language: English, always, subject and body.

**Body**: why the change was made and what it does at a high level, in bullets that start with a verb,
wrapped at 100 columns. It points to `docs/decisions.md` when a decision explains it. It is not a
code review.

```
perf(neotree): open the changes tree without listing ignored files

- Passes --ignored=no to the changes view's git status: it listed every node_modules
  file (571,230 lines) and took 4.5 s to open
- See docs/decisions.md (D-01)
```

## Commit organization

Group related files into logical commits: a performance fix, a plugin update and a docs change are
three commits, not one. The lockfile goes with the change that needed it, or alone as
`chore(plugins): ...` when it is a plain update.

# Pull requests

Check `gh` first: `command -v gh && gh auth status`. With `gh`, create the PR with `--base develop` and
a title equal to the first commit's subject; the release PR goes from `develop` to `main`. Without it, give the owner the title and the body to
paste. The body follows this template, with no empty section:

```markdown
## Summary
- One to three bullets: what was done

## Why
- The problem it solves

## Changes
- `<type>(<scope>): <subject>` per notable commit

## Testing
- What was run to verify it (headless checks, manual steps)
```

# Never

- `git push` without the owner asking, `git add .`, `git add -A`
- Commit without the owner asking, or straight to `main` or `develop`
- Mix unrelated changes in one commit
- Messages in any language other than English, vague or in the past tense ("added", "changes")
- Co-author or generated-by trailers
