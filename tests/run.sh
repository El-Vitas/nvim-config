#!/usr/bin/env bash
# Pruebas de la config que necesitan el editor completo. Cada una corre en un
# repo temporal y con XDG_STATE_HOME temporal, para no pisar las sesiones ni la
# base de review guardadas.
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
  printf '# Sección %s\n\nTexto de la sección %s con una línea larga que ocupa espacio y se envuelve cuando la ventana es angosta.\n\n| a | b |\n|---|---|\n| %s | x |\n\n```lua\nprint(%s)\n```\n\n' "$i" "$i" "$i" "$i"
done > doc.md
printf '# Otro\n\nhola\n' > other.md
printf 'print(1)\n' > code.lua
git add . && git commit -qm base
# doc.md con cambios contra HEAD, para que el split de review arme el par.
printf 'línea nueva\n' >> doc.md

status=0
for t in mdpreview; do
  echo "── $t"
  code=0
  out="$(XDG_STATE_HOME="$tmp/state" timeout 120 nvim --headless -c "luafile $here/$t.lua" 2>&1)" || code=$?
  printf '%s\n' "$out" | tr '\r' '\n' | grep -E '^(FALLA|ERROR|[a-z]+: ok=|mensajes:)' || true
  if [ "$code" -ne 0 ]; then
    echo "   salió con código $code"
    status=1
  fi
done
exit "$status"
