#!/usr/bin/env bash
# Config tests that need the full editor. Each one runs in a temporary repo with
# a temporary XDG_STATE_HOME, so the saved sessions and the review database are
# not overwritten.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

repo="$tmp/repo"
mkdir -p "$repo"
cd "$repo"
git init -q -b main
git config user.email test@test
git config user.name test
for i in $(seq 1 12); do
  printf '# Section %s\n\nText of section %s with a long line that takes up a lot of space and wraps when the window is narrow.\n\n| a | b |\n|---|---|\n| %s | x |\n\n```lua\nprint(%s)\n```\n\n' "$i" "$i" "$i" "$i"
done > doc.md
printf '# Other\n\nhello\n' > other.md
printf 'print(1)\n' > code.lua
git add . && git commit -qm base
# doc.md with changes against HEAD, so the review split builds the pair.
printf 'new line\n' >> doc.md

status=0
for t in mdpreview; do
  echo "── $t"
  code=0
  out="$(XDG_STATE_HOME="$tmp/state" timeout 120 nvim --headless -c "luafile $here/$t.lua" 2>&1)" || code=$?
  printf '%s\n' "$out" | tr '\r' '\n' | grep -E '^(FAIL|ERROR|[a-z]+: ok=|messages:)' || true
  if [ "$code" -ne 0 ]; then
    echo "   exited with code $code"
    status=1
  fi
done
exit "$status"
