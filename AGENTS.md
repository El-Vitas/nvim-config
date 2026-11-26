# AGENTS.md

Config personal de Neovim 0.12 con lazy.nvim. `~/.config/nvim` es un symlink a esta carpeta. Prima la cautela sobre la velocidad: un cambio que rompe el editor deja al dueño sin su herramienta de trabajo.

## Mapa

| Ruta | Qué hay |
|---|---|
| `init.lua` | Bootstrap de lazy, leader, módulos propios y `lazy.setup` |
| `lua/config/` | Módulos propios: opciones, cheatsheet (`keymaps.lua`), límite de buffers, binarios (`open.lua`), estado de ocultos (`hidden.lua`), grilla de tablas markdown (`mdtable.lua`), preview de markdown (`mdpreview.lua`) |
| `tests/` | Pruebas con el editor completo y las teclas reales (`tests/run.sh`) |
| `lua/plugins/` | Un spec de lazy por plugin o grupo |
| `lua/material_folders.lua` | Tabla generada por `../material-font`. No se edita a mano |
| `fonts/` | `MaterialFolders.ttf` y su regla de fontconfig, copiadas de `../material-font` para el instalador |
| `install.sh` | Instalador de una línea para otra máquina (lo documenta `README.md`) |
| `docs/business-rules/` | Qué tiene que hacer el editor. Se consulta con el CLI |
| `docs/decisions.md` | Por qué está hecho así, con las mediciones (`D-NN`) |
| `tools/rules-cli/` | CLI del registro de reglas (bun) |
| `.agents/skills/` | Skills del repo; `.claude/skills/` son enlaces a ellas |

Repos hermanos en `~/Dev/nvim`: `review-mode/` (plugin de revisión, publicado como `El-Vitas/review-mode.nvim`; con `dev = true` lazy usa la copia local si existe y si no la de GitHub) y `material-font/` (generador de la fuente de iconos de carpetas). Si se regenera la fuente, se copia de nuevo a `fonts/`.

## Antes de cambiar algo

1. Consulta las reglas del área: `bun run rules:query --features --names` y `bun run rules:query --feature FEA-XXX`. Un cambio que rompe una regla activa es un bug, aunque el código quede más lindo. La skill `business-rules` explica cómo agregar o reemplazar reglas.
2. Lee la decisión que el código cita (`D-NN` en `docs/decisions.md`). Varias partes tocan internas de plugins (neo-tree, gitsigns, render-markdown) y el porqué está ahí.
3. Una decisión nueva o cambiada se escribe en `docs/decisions.md` en el mismo cambio.

## Reglas del repo

- **Archivos.** Todo cambio en un archivo se hace con las herramientas de edición, archivo por archivo. Nunca con `sed -i`, heredocs, `python -c` ni redirecciones. El CLI de reglas y lazy (que reescribe `lazy-lock.json`) son las únicas herramientas que escriben archivos del repo.
- **Idioma.** Mensajes de commit, `README.md` y los textos que ve el usuario dentro de Neovim (notificaciones, cheatsheet), en inglés. Comentarios, docs internos y reglas, en español neutro, sin voseo ni modismos regionales.
- **Comentarios.** Explican el porqué en presente. La historia y las mediciones van en `docs/decisions.md`. Detalle en la skill `code-comments`.
- **Prosa.** Docs, reglas y cuerpos de commit siguen la skill `vitas-writing`.
- **Git.** Skill `git-flow`: git flow siempre (rama desde `develop`, PR a `develop`, `develop` → `main`), nunca `git add .`, commit y push solo cuando el dueño lo pide, sin trailers de coautoría.
- **Subagentes.** Antes de lanzar subagentes se le pregunta al dueño qué modelo y cuántos.
- **Rendimiento.** `<leader>e`, `<leader>s` y cambiar de buffer tienen presupuesto (regla "Abrir el árbol y cambiar de buffer no traban el editor"). Nada sincrónico contra git o el disco en autocmds de `BufEnter`, `WinEnter`, renders del árbol ni la statusline.
- **Temporizadores.** Un `vim.uv.new_timer()` reutilizado por módulo, no `vim.defer_fn` + `stop()` (D-13).
- **Autocmds.** Siempre con `augroup` y `clear = true`.

## Cómo verificar un cambio

`tests/run.sh` prueba lo que tiene casos difíciles de ver a mano, como el preview de markdown. Corre en un repo temporal y no toca las sesiones. Si se cambia algo de lo que prueba, se corre. Además, lo mínimo para cualquier cambio:

```bash
# arranca sin errores ni avisos
nvim --headless +'lua vim.defer_fn(function() print(vim.api.nvim_exec2("messages",{output=true}).output) vim.cmd("qa!") end, 2000)'
# salud de los plugins
nvim --headless +'checkhealth vim.deprecated lazy vim.lsp' +'w! /tmp/health.txt' +qa
```

Para cambios en el árbol, la sesión o el arranque, mide el bloqueo en un repo grande antes y después, con `XDG_STATE_HOME` apuntando a una carpeta temporal para no pisar las sesiones reales. Las cifras de referencia están en `docs/decisions.md`.

review-mode tiene su propia suite (`tests/`, busted vía plenary) y sus docs (`docs/decisions.md`, `docs/performance.md`).
