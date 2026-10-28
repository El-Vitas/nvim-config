---
name: business-rules
description: Use when querying, adding, or modifying the behavior rules of this Neovim config in docs/business-rules/ (what the editor must do — tree, session, search, review, markdown…). Do NOT read YAML files directly — use the bun CLI commands.
metadata:
  version: '2.1-nvim'
  scope: [general]
  auto_invoke: 'When you need to understand what a feature of the editor must do, check rule lineage, or propose new rules'
---

# Business Rules

Adapted from the `business-rules` skill of the `mio` repo. Same CLI, same lifecycle. In this repo the
"business" is the editor's behavior as the user experiences it.

## DO NOT read YAML directly

The YAML files in `docs/business-rules/` are the source of truth for humans. You never open them. You use CLI commands, from the root of this repo. The first time on a machine, run `bun install` and `bun run rules:build`.

## What is a rule here

A rule documents **what the editor must do** — the behavior the user relies on, a constraint, a guarantee. If it stops holding, it is a bug.

### Belongs here

- WHAT the editor must do: "<leader>e reopens the tree in the same mode it was closed", "the changes tree never lists git-ignored files", "the session is saved within one second of the last buffer change".
- Constraints and guarantees: limits, what must never happen (losing unsaved work, overwriting a binary file with placeholder text), response-time budgets the user perceives.

### Does NOT belong here

Implementation jargon: plugin internals, function names, file paths, flags, timer types. Those go in `docs/decisions.md` (the technical *why*).

| Wrong (implementation) | Right (what the editor must do) |
|---|---|
| "Pass `--ignored=no` in `before_git_status`" | "Opening the changes tree takes under 100 ms even in a repo with a large ignored folder" |
| "Debounce persistence.save with a 1 s uv timer" | "The session reflects the last file opened, at most one second late" |
| "Use `renderer.redraw` on WinClosed" | "The open-file marker in the tree disappears when the file is no longer visible in any window" |

The litmus test: **can you explain this rule to the user of the editor without naming a plugin, a function or a file?** If not, it is a decision, not a rule.

## Query

```bash
bun run rules:query --features --names     # which areas exist
bun run rules:query --feature FEA-TRE      # active rules of an area
bun run rules:query --feature FEA-TRE --status all
bun run rules:query --id BR-xxxxxxx        # one rule with its full evolution history
bun run rules:query                        # every active rule, all areas
bun run rules:query --status all           # every rule, any status
bun run rules:query --features             # areas with rule counts per status
bun run rules:query --search sesion
```

Output is JSON. The `lineage` field in `--id` queries shows every past version with `superseded_reason`.

## Add or modify

Pipe YAML to `rules:add`. **Do NOT include `id`** — it is a deterministic hash of feature + rule text:

```bash
bun run rules:add << 'YAML'
feature: FEA-XXX        # Required
feature_name: Area name
feature_purpose: What it covers.
feature_scope: area-name-or-cross-cutting
status: active          # active | superseded | inactive
title: Short title
rule: The rule itself.  # Required
why: Reason it exists.
context: Scope, exceptions, related decision in docs/decisions.md.
supersedes: ~           # Pass BR-xxx when replacing an existing rule
scenarios:
  - title: Scenario name
    given: Context
    when: Trigger
    then: Expected result
YAML
```

- ID auto-generated as `BR-{sha256(feature + ":" + rule)[:7]}` — same rule → same ID.
- Duplicate content is skipped silently.
- `supersedes` target must exist and be `active`.
- Status must be `active`, `superseded` or `inactive`.
- Always add `feature_name`, `feature_purpose` and `feature_scope` when creating a new area. Omit them for an existing one.
- Rules are written in neutral Spanish (the user's language); ids and statuses stay in English.

## Supersede, never rewrite history

`supersedes: BR-xxx` creates the new rule, marks the old one `superseded` with `superseded_by`, and backs up the YAML to `history/`. A rule that turned out wrong or outgrown is superseded, not deleted.

## Delete — only for a material error

```bash
bun run rules:delete --id BR-xxxxxxx
```

Only for a rule that should never have existed: the wrong feature id, the same rule sent twice, a half-written submission. It refuses rules that superseded or were superseded by another.

## After humans edit YAML

```bash
bun run rules:build    # Sync YAML -> SQLite
```

## Generated files

`rules.db*` and `history/` are gitignored. YAML is the source of truth.
