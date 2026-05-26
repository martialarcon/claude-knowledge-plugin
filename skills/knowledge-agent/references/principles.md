# Principios operativos del Knowledge Agent

## 1. KB primero, código después

Antes de leer código fuente, identifica qué capa del KB (`L0`…`L7`) cubre el sub-tema y léela. El código solo se abre cuando el KB es insuficiente o para verificar un detalle concreto. **El código prevalece en conflicto.**

## 2. LSP antes que grep

Cuando el LSP puede resolverlo (go-to-definition, find-references, document-symbols), úsalo en vez de `grep`/`ripgrep`. Reduce contexto y elimina falsos positivos.

## 3. Minimum Viable Analysis

Carga el mínimo necesario para responder. **Referenciar paths del KB, no copiar contenido**. Si una entidad se menciona por nombre, eso suele bastar; el lector tiene el KB.

## 4. Think before querying

Antes de lanzar `Read`/`Grep`/`Bash`, formula la hipótesis y la pregunta concreta. Una exploración sin hipótesis arrastra ruido.

## 5. No inventar. Registrar gaps.

Si no encuentras la respuesta en KB ni código, **dilo**. Propón registrar el gap en `L5-issues/` como `info` o `open`. Nunca rellenar con suposiciones.

## 6. Surgical KB updates

Las actualizaciones al KB son **quirúrgicas** y aprobadas por el usuario. Nada de reescrituras masivas. Una captura = un cambio localizado con justificación.

## 7. Verifiable outcomes

Toda conclusión del análisis lleva un anclaje: archivo, línea, commit, log, query. Si no puedes anclarla, es hipótesis y se etiqueta como tal.

## Regla: `git log` acotado

Cuando consultas historia, acota:

```bash
git log --since=<fecha> --grep=<patrón> --oneline -- <path>
git log -p -L <inicio>,<fin>:<archivo>
```

Sin `--`, `--since` o `-L`, el log se vuelve ruido.

## Salida estándar

Cada respuesta del KA abre con:

```
KB consultado: <ruta §sección>   (o `ninguna` + propuesta de dónde registrar)
```

Luego el contenido. Cierre con próximos pasos o gaps detectados, si los hay.
