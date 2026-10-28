# Reglas de comportamiento de la config

Este registro dice **qué tiene que hacer el editor**: qué muestra cada árbol, cuándo se guarda la sesión, qué cuenta como archivo oculto. Si una regla deja de cumplirse, hay un bug, aunque el código "funcione".

El **por qué técnico** de cada implementación (qué flag de git se usa, por qué un temporizador y no otro) no va acá. Va en [`../decisions.md`](../decisions.md). Una regla se tiene que poder explicar sin nombrar un plugin ni un archivo; una decisión, no.

## Archivos

- `fea-*.yaml`: un archivo por área del editor (árbol, sesión, búsqueda…). Es la fuente de verdad y se versiona.
- `fea-template.yaml`: plantilla para un área nueva. El CLI no la indexa.
- `rules.db` y `history/`: los genera el CLI y no se versionan.

## Cómo se usa

No se leen ni se editan los YAML a mano: se consultan y se agregan con el CLI, que necesita [bun](https://bun.sh). La primera vez, `bun install` en la raíz de este repo.

```bash
bun run rules:build                    # reconstruye rules.db desde los YAML
bun run rules:query --features --names # qué áreas existen
bun run rules:query --feature FEA-TRE  # reglas vigentes de un área
bun run rules:query --id BR-xxxxxxx    # una regla con su historia
bun run rules:add < regla.yaml         # agrega una regla (el id lo genera el CLI)
bun run rules:delete --id BR-xxxxxxx   # solo para un error material
```

La skill `.agents/skills/business-rules` explica el formato de `rules:add` y el ciclo de vida completo.

## Convenciones

- Área: `FEA-` más tres letras (`FEA-TRE`, `FEA-SES`).
- Regla: `BR-` más los primeros 7 caracteres de un sha256 del área y el texto de la regla. Lo calcula el CLI, así que la misma regla siempre tiene el mismo id.
- Estado: `active`, `superseded` o `inactive`.
- Toda regla lleva `why`. Una regla sin razón no se agrega.
- Una regla que cambió se reemplaza con `supersedes`, y la vieja queda enlazada a la nueva. `delete` es solo para lo que nunca debió existir: el área equivocada, la misma regla enviada dos veces, un envío a medias.
