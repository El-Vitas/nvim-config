# Decisiones técnicas de la config

Por qué cada parte de la config está hecha como está. Lo que el editor **debe hacer** está en [`business-rules/`](business-rules/README.md); acá va **cómo** se logra y qué se descartó. Cada decisión tiene un id estable (`D-NN`) al que apuntan los comentarios del código.

Las mediciones son de Neovim sin interfaz (`--headless`) en el repo FastCase: 1 402 archivos versionados, 38 034 carpetas y un `node_modules` ignorado con 571 230 archivos. Los scripts de medición se corren con `nvim --headless` y miden cuánto bloquea cada acción (el tiempo hasta que la tecla devuelve el control). La interfaz real agrega el dibujo en la terminal, unos pocos milisegundos.

## Resultado de la optimización del 2026-10-28

| Acción | Antes | Después |
|---|---|---|
| `<leader>s` (abrir el árbol de cambios) | 4 481 ms | 14–20 ms |
| `<leader>e` (abrir el árbol de archivos) | 41 ms | 6–11 ms |
| Cambiar de buffer | 41 ms | 0,5–0,6 ms |
| Abrir un proyecto JS/TS (vigilancia de archivos del LSP) | 4 600 ms bloqueado | delegado a `inotifywait` |
| Arranque hasta la primera pantalla | ~265 ms | ~265 ms |

El arranque no cambió. Lo domina abrir el primer archivo (las queries de resaltado de TypeScript cuestan ~70 ms y review-mode carga sus módulos). Pasar plugins a carga diferida ahorró poco frente a eso.

Lua no era el problema, así que reescribir partes en Rust no habría ayudado. Todas las causas eran trabajo innecesario hecho de forma sincrónica: pedirle a git medio millón de líneas que nadie mostraba, guardar la sesión en cada salida de buffer, recorrer 38 000 carpetas en el hilo de la interfaz.

---

## D-01 · El árbol de cambios no le pide a git los archivos ignorados

`lua/plugins/neotree.lua`, función `skip_ignored_in_changes`.

La vista de cambios de neo-tree (`git_status`) corre `git status --untracked-files=all --ignored=traditional` de forma sincrónica. Con esa combinación git lista **cada** archivo ignorado. En FastCase eso son 571 230 líneas que neo-tree parsea en Lua, y `<leader>s` bloqueaba 4,5 s. Esa vista descarta después el estado de ignorado (`sources/git_status/lib/items.lua`, filtro `status ~= "!"`), así que el trabajo no servía para nada.

La config se suscribe al evento público `before_git_status` de neo-tree y cambia `--ignored=traditional` por `--ignored=no`, solo en la llamada que trae `--untracked-files=all` (la de la vista de cambios). El árbol de archivos usa otras llamadas y sigue ocultando los ignorados.

- **Medido:** 4 481 ms → 37 ms en el primer experimento; 14–20 ms con todo lo demás aplicado.
- **Descartado:** `core.fsmonitor` y `core.untrackedCache` de git. Aceleran el recorrido del disco, pero el costo estaba en el volumen de texto devuelto, no en el recorrido.
- **Fragilidad:** depende de que neo-tree siga emitiendo `before_git_status` con `status_args`. Si deja de hacerlo, `<leader>s` vuelve a ser lento, pero no se rompe nada.

## D-02 · La sesión se guarda con un segundo de calma, no en cada BufLeave

`lua/plugins/persistence.lua`.

El guardado automático corría `persistence.save()` en cada `BufLeave` de un archivo, para que la sesión quedara al día aunque se cerrara la terminal de golpe. Cada guardado es un `:mksession` más un `git branch --show-current` sincrónico, entre 25 y 38 ms. `BufLeave` se dispara al pasar al árbol, al abrir Telescope y al cambiar de buffer, así que todas esas acciones cargaban ese costo.

Ahora `BufEnter` y `BufWritePost` reinician un temporizador de 1 s y se guarda una vez cuando hay calma. `FocusLost` guarda en el acto y el `VimLeavePre` propio de persistence guarda al salir. El guardado respeta `persistence.active()`; antes seguía guardando después de `<leader>qd`.

- **Medido:** cambiar de buffer pasó de 41 a 2,6 ms solo con esto.
- **Costo aceptado:** si la terminal muere, la sesión puede quedar hasta 1 s atrasada.

## D-03 · El ● de archivo abierto se repinta con `renderer.redraw`

`lua/plugins/neotree.lua`, función `redraw_tree`.

La config tenía un `Neotree refresh` diferido en `BufWinEnter`/`WinClosed`/`BufDelete` para actualizar el ●. `refresh` no es un argumento válido de `:Neotree` y fallaba con `Invalid argument: refresh`, escondido por un `pcall`. Antes de fallar, el parser corría `git rev-parse --verify refresh` de forma sincrónica. Nunca refrescó nada.

neo-tree repinta solo cuando se agrega o se borra un buffer. Al cerrar un split el buffer sigue cargado, y el ● quedaba pegado. La config llama a `renderer.redraw(state)` 100 ms después de `BufWinEnter` o `WinClosed`, con un solo temporizador reutilizado. `redraw` vuelve a evaluar los componentes de los nodos que ya existen, sin escanear el disco ni llamar a git. Las ventanas flotantes no disparan el repintado, porque no cuentan como "abierto en un panel" y cada vista previa de Telescope repintaba el árbol.

El ● consulta un set de archivos visibles que se arma una vez por render (`before_render`). Antes recorría todos los buffers por cada archivo del árbol: 5,3 ms con 1 400 nodos y 60 buffers, contra 0,13 ms del set. El fondo del archivo actual se ubica por id del nodo (NuiTree devuelve su línea) en vez de recorrer todas las líneas.

- **Verificado:** el ● de un split cerrado desaparece en menos de 300 ms; cambiar de buffer sigue en 0,6 ms.

## D-04 · La verificación de ignorados de `hidden.lua` es asíncrona

`lua/config/hidden.lua`, función `asegurar_filtro`.

En el primer render, neo-tree todavía no marcó los ignorados y los muestra. `hidden.lua` verifica el resultado contra git (`git check-ignore --stdin` con los paths visibles) y re-navega si quedó alguno, con un tope de 6 intentos. La verificación esperaba a git con `:wait()` después de cada render, también en los renders del árbol de cambios, que no tiene ignorados que filtrar.

Ahora corre con `vim.system` y un callback, solo tras renders del árbol de archivos, y no lanza una nueva mientras otra sigue en curso.

- **Medido:** en FastCase su peso fue bajo (dentro del ruido). Se cambió igual porque esperar a un proceso externo en cada render es un riesgo que crece con el repo.

## D-05 · La vigilancia de archivos del LSP la hace `inotifywait`

Sin cambios en la config. Requiere el paquete `inotify-tools` del sistema (`sudo dnf install inotify-tools`).

Cuando vtsls arranca, pide vigilar los archivos del proyecto (`workspace/didChangeWatchedFiles`). Neovim elige cómo hacerlo en `runtime/lua/vim/lsp/_watchfiles.lua`. En Linux usa `inotifywait` si existe, y si no cae en `watchdirs`, que recorre en Lua cada carpeta y crea un watcher por carpeta, en el hilo de la interfaz.

- **Medido:** `watchdirs` sobre FastCase bloqueó 4,6 s (38 034 carpetas). Pasaba al abrir cualquier archivo JS/TS, y explica gran parte de la lentitud "al abrir".
- **Descartado:** apagar `didChangeWatchedFiles` en las capacidades del cliente. Funciona, pero el servidor pierde los avisos de archivos creados o borrados fuera del editor.
- **Límite del sistema:** `fs.inotify.max_user_watches` es 133 052, sobrado para 38 000 carpetas.

## D-06 · Carga diferida de lo que no se usa al arrancar

| Plugin | Antes | Ahora |
|---|---|---|
| telescope | `lazy = false` sin motivo documentado | `cmd = "Telescope"` + sus atajos |
| nvim-cmp | al arranque | `event = "InsertEnter"` |
| harpoon | al arranque (atajos definidos en `config`) | `keys` |
| nvim-lspconfig, mason, mason-lspconfig | al arranque | `event = { "BufReadPre", "BufNewFile" }`, mason como dependencia para que su PATH esté listo antes del primer servidor. mason-lspconfig además lleva `lazy = true`: un spec sin disparador es raíz y lazy lo carga al arrancar aunque sea dependencia de otro (22 ms) |
| nvim-window-picker | al arranque | `lazy = true`; neo-tree lo pide con `require` al usar `w` |
| `material_folders` (4 600 líneas, ~9 ms) | al leer el spec de neo-tree | en el primer render de una carpeta |
| nvim-lsp-file-operations | solo al apretar `<leader>e` | `event = "VeryLazy"` |

neo-tree queda con `lazy = false` a propósito, porque abrir `nvim .` (`hijack_netrw_behavior`) y restaurar el árbol necesitan que esté cargado antes del primer buffer.

lsp-file-operations alojaba los atajos `<leader>e`/`<leader>E` y solo se cargaba al apretarlos. Si el árbol se abría con `<leader>s` o al restaurar la sesión, mover un archivo en el árbol no actualizaba los imports.

## D-07 · `vim.snippet` en vez de LuaSnip

LuaSnip y cmp_luasnip no tenían ningún snippet propio cargado. Solo expandían los snippets que manda el servidor de lenguaje, y Neovim 0.12 hace eso con `vim.snippet.expand`. Se quitaron los dos plugins; cargar LuaSnip costaba 12 ms en el arranque.

## D-08 · Los atajos del árbol viven en el spec de neo-tree

`<leader>e` y `<leader>E` pasaron de ser funciones anónimas en el spec de lsp-file-operations a funciones locales (`toggle_tree`, `reveal_in_tree`) registradas en el spec de neo-tree. Reutilizan `find_neotree_win()` en vez de repetir su recorrido de ventanas.

Las dos abren el árbol por `nt_exec`, que delega en `require("review").neotree_exec`. Esa función inyecta la base de review cuando el modo es cambios. Abrir con el comando `:Neotree` pelado ignoraba la base y el árbol de cambios volvía a `git status` plano.

## D-09 · Telescope con `telescope-fzf-native`

El ordenador por defecto de Telescope está escrito en Lua. `telescope-fzf-native` usa el algoritmo de fzf compilado en C, y la propia documentación de Telescope lo recomienda. Se compila con `make` al instalarlo; si la compilación falla, `pcall(load_extension)` deja Telescope con el ordenador en Lua.

- **No medido:** la medición automática del filtrado no fue confiable y no se usa como evidencia. Se adoptó por recomendación de upstream.

## D-10 · treesitter en la rama `main`

La config llamaba a `require("nvim-treesitter.configs")`, que no existe en la rama `main` instalada. El `pcall` lo escondía, así que `ensure_installed` nunca corrió: faltaban los parsers de `html` y `css`, y la indentación por treesitter nunca estuvo activa. Ahora se consulta `get_installed()` y se instala solo lo que falta, de forma asíncrona.

La indentación por treesitter sigue apagada. En `main` es experimental, y prenderla cambiaría cómo indenta el editor.

## D-11 · Copilot se configura en `init`

`plugin/copilot.vim` mapea `<Tab>` en el momento de cargarse si `g:copilot_no_tab_map` todavía no existe. La config definía esa variable en `config`, que corre después de cargar el plugin, y quedaba un `<Tab>` global de Copilot. Funcionaba por casualidad, porque la expresión del mapeo revisa la variable en cada pulsación. Las variables pasaron a `init`. Se quitó `build = ":Copilot setup"`, que es una autenticación interactiva y no un paso de compilación. En una máquina nueva se corre `:Copilot setup` una vez a mano.

## D-12 · Neovim 0.12.6 y plugins al día, con nvim-scrollbar fijado a v1

Neovim pasó de 0.12.1 a 0.12.6 (checksum verificado contra el publicado en GitHub). Entre medio está la corrección de CVE-2026-11487, ejecución de comandos vía `vim.secure.read()`, corregida en 0.12.3. La 0.12.1 quedó respaldada en `/opt/nvim-linux-x86_64.0.12.1.bak`.

Se actualizaron 15 plugins. Antes de dar por buena la actualización se revisó que las internas que usa la config sigan con la misma forma:

- **gitsigns:** `Repo:file_info(file, revision)` y `object_missing` (parche de renombrados).
- **neo-tree:** `git.status`, `worktrees[...].status_diff`, `before_git_status`, `fs._navigate_internal`, `renderer.get_expanded_nodes`, `force_open_folders`.
- **render-markdown:** `core.preview.get` y `.buffers`, `core.manager.attached`, `state.get`.

nvim-scrollbar avisaba en cada arranque que el 2026-11-16 su `main` pasa a v2, que rechaza las opciones de v1 y la API de handlers que usa review-mode para sus marcas. Se fijó `branch = "v1"`, que apunta al mismo commit que había antes de actualizar. Migrar a v2 queda pendiente ([issue #121](https://github.com/petertriho/nvim-scrollbar/issues/121)).

## D-13 · Un temporizador reutilizado en vez de `vim.defer_fn` + `stop()`

`vim.defer_fn` crea un temporizador que se cierra solo al dispararse. Si se detiene con `stop()` antes de que dispare, nunca se cierra y el handle queda abierto. `mdtable.lua` hacía eso en cada ráfaga de eventos de markdown (cada edición, cada resize). El patrón de la config es un `vim.uv.new_timer()` por módulo, con `stop()` y `start()` en cada evento. Lo usan `mdtable.lua`, `persistence.lua` y `neotree.lua`.

## D-14 · Todo vive en `~/Dev/nvim`

| Carpeta | Qué es | Git |
|---|---|---|
| `config/` | Esta config. `~/.config/nvim` es un symlink a ella | `El-Vitas/nvim-config` |
| `review-mode/` | El plugin de revisión, cargado con `dir =` desde `lua/plugins/review.lua` | repo propio, sin remoto |
| `material-font/` | Generador de la fuente de iconos de carpetas. Incluye `out/MaterialFolders.ttf` y la regla de fontconfig, que antes solo existían instaladas en el sistema | repo propio, sin remoto |

## D-15 · Documentación de reglas con el CLI de `mio`

Las reglas de comportamiento usan el mismo registro que el repo `mio` (`tools/rules-cli`, copia sin cambios de `packages/rules-cli`). Así se consultan con los mismos comandos y la misma skill. Neovim no lee `package.json` ni `node_modules/`, porque solo busca en `lua/`, `plugin/` y las demás carpetas del runtimepath.

## D-16 · Parche de gitsigns para archivos renombrados contra una base

`lua/plugins/gitsigns.lua`.

Con una base explícita (`change_base <commit>`, que review-mode fija al elegir base), un archivo renombrado se pintaba entero como agregado. `Repo:ls_tree` busca el renombrado con `self:diff_rename_status(revision, true)[path]`: ese mapa tiene claves relativas al repo y `path` llega absoluto, así que nunca coincide. Verificado en gitsigns `d4854fa` (`lua/gitsigns/git/repo.lua:757`).

El parche envuelve `Repo.file_info` y solo actúa cuando gitsigns ya marcó `object_missing`. Pregunta a `review.core.git.rename_source` si el archivo es destino de un renombrado contra la base y, si lo es, devuelve el blob del path viejo. Todo lo demás queda en manos de gitsigns.

- **Cuándo borrarlo:** si gitsigns pasa a buscar el renombrado con el path relativo, `object_missing` deja de llegar en ese caso y el parche no se dispara. Se puede borrar sin más.
- **Si gitsigns cambia la API:** sin `Repo.file_info`, la config avisa al arrancar en vez de fallar en silencio.
- **Verificado:** un renombrado contra la base muestra 0 líneas agregadas (antes, el archivo entero).

## D-17 · Hallazgos de la revisión de calidad del 2026-10-28

La revisión corrió `lua-language-server --check`, `jscpd` y cuatro revisores en paralelo sobre config y review-mode. Los reportes completos quedaron fuera del repo. Lo que se corrigió en la config:

| Problema | Efecto | Arreglo |
|---|---|---|
| `return true` en el `BufReadCmd` de `open.lua` | En Lua, un valor verdadero borra el autocmd (`:h nvim_create_autocmd`). El segundo binario de la sesión se abría como texto editable y un `:w` lo modificaba | Sin retorno |
| `++bin` leído de `'binary'` dentro de `BufReadCmd` | `:OpenRaw` sobre un archivo no abierto volvía a mostrar la pantalla de ayuda en bucle | Se lee `v:cmdarg` y se activa `'binary'` antes de leer |
| Patrones de binarios en minúscula | `FOTO.PNG` se abría como texto | Patrones en los dos casos |
| Guardado diferido de persistence sin filtro | Un `git commit` con `EDITOR=nvim` pisaba la sesión con `COMMIT_EDITMSG` | Mismo filtro que persistence al salir (`gitcommit`, `gitrebase`, `jj`) |
| Copilot en todos los buffers | El contenido de `.env` y llaves salía a GitHub | `copilot_filetypes` y `b:copilot_enabled = false` por nombre de archivo |
| lua_ls sin la API de Neovim | 9 `undefined-global` por archivo de esta config, sin completado de `vim.*` | Receta de nvim-lspconfig, solo para carpetas de config o plugin de Neovim |
| Capacidades de cmp solo en vtsls | eslint, tailwind y lua_ls no recibían las de cmp | `vim.lsp.config("*", { capabilities })` |
| Recorte de inlay hints por byte | Cortaba caracteres UTF-8 a la mitad | `strchars` / `strcharpart` |
| mdtable apagaba el wrap en todo markdown | `<leader>w` no tenía efecto en archivos sin tablas | El wrap se toca solo si hay tablas |
| mdtable ignoraba el modo crudo | `<leader>m` dejaba la grilla dibujada | Respeta `state.enabled` de render-markdown y el toggle la refresca |
| `ignore_ft` y `pcall` en el arranque de treesitter | Entradas muertas y errores reales escondidos | Solo buffers de archivo y solo con parser |
| `c.blue` inexistente en lualine | El indicador "md split" salía gris | Color definido |
| Opciones que no existen o son el default (`matching` de cmp, `options` de persistence) | Ruido que no hace nada | Borradas |

En review-mode, los arreglos y su porqué están en `review-mode/docs/decisions.md` (B7 a B15 y D24 a D26).

Lo que queda pendiente, con el motivo:

- **`automatic_enable` de mason-lspconfig** habilita todo servidor instalado con mason (pyright está habilitado aunque la config no lo menciona). Decidir qué servidores arrancan es del dueño.
- **`sidebar._refresh` de review-mode** hace un `Neotree refresh` en cada cambio de comentarios, para un marcador 💬 que ningún renderer dibuja. Con D-01 ese refresh cuesta unos 18 ms; quitarlo o terminar el marcador es una decisión sobre la feature.
- **El gutter de comentarios** dibuja con el `lnum` guardado mientras el resaltado sigue al extmark: al insertar líneas sin guardar, el corchete queda una línea corrido hasta guardar. Arreglarlo toca la función que se evalúa por cada línea en cada redibujado.

## D-18 · Una paleta compartida

`lua/config/palette.lua` tiene los 13 colores que tienen que coincidir entre el tema, la statusline, el árbol, markdown y el cheatsheet (unos 60 usos de literales hex repetidos en cinco archivos). Los colores de un solo uso (los de cada tipo de carpeta, los fondos de los títulos de markdown) quedan en su archivo.

- **Verificado:** el volcado de los 2 586 grupos de resaltado y del tema de lualine es idéntico antes y después. La única diferencia, `DevIconLogos`/`DevIconASM`, es ruido de nvim-web-devicons: dos extensiones comparten nombre con colores distintos y gana la que se recorra primero.

## D-19 · Limpieza de opciones y semántica de cierre de buffers

- Se borraron opciones iguales al valor por defecto de su plugin (verificado en el código de cada uno): nvim-ts-autotag, treesitter-context, which-key (`delay`), nvim-scrollbar, onedarkpro (`terminal_colors`, `highlight_inactive_windows`), nvim-web-devicons (`color_icons`). Quedan solo las que cambian algo, con su porqué.
- which-key declara sus grupos en `opts.spec` en vez de un `config` propio.
- El cheatsheet lista los atajos LSP que trae Neovim 0.12 (`grn`, `grr`, `gri`, `grt`, `gra`, `gO`) y ya no tiene el respaldo para versiones sin `footer` en ventanas flotantes.
- `buffers.lua` cierra con `:bdelete` y no con `nvim_buf_delete` (que es `:bwipeout`): la quickfix de cambios de review, las marcas y el jumplist siguen apuntando al archivo, y review-mode recibe el `BufDelete` con el que libera sus caches.

