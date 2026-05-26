# INSTALL_FOR_AGENTS.md

Guion de instalación pensado para que un agente (Claude Code u otro) ejecute la instalación sin intervención humana más allá de aportar valores de configuración.

Si eres un humano, lee `README.md`.

## Precondiciones

- `bash`, `git`, `jq`, `sed`, `find` en PATH.
- Permiso para escribir en el directorio `<target>`.
- Si el operador usa Jira / Linear: `~/secrets/<tracker>_token.txt` (no obligatorio para instalar; sí para usar el tracker en runtime).

## Inputs que necesitas pedir al operador

| Variable | Ejemplo | Notas |
|---|---|---|
| `target` | `~/git/aecoc` | Repo destino. Debe existir o se creará. |
| `name` | `aecoc` | Slug humano del proyecto. |
| `slug` | `ka` | Prefijo de slash-commands (`/ka analyze`). |
| `kb-path` | `~/git/aecoc-knowledge` | Dónde vive el KB. Puede ser el propio target. |
| `tracker` | `jira` \| `linear` \| `github` | Tracker activo. |
| `issue-prefix` | `ATP` | MAYÚSCULAS, regex `^[A-Z][A-Z0-9]+$`. |
| `tracker-url` | `https://aecoc-team.atlassian.net` | Base del tracker. |
| `repos-root-env` | `AECOC_REPOS_ROOT` | Var de entorno que apunta a raíz de repos compañeros. |
| `bootstrap-kb` | `true`/`false` | Copiar `kb-skeleton/` al target. |

**No inventes valores.** Si el operador no aporta uno, pregúntalo antes de continuar.

## Paso 1: instalar

```bash
scripts/init.sh \
  --target "$TARGET" \
  --name "$NAME" \
  --slug "$SLUG" \
  --kb-path "$KB_PATH" \
  --tracker "$TRACKER" \
  --issue-prefix "$ISSUE_PREFIX" \
  --tracker-url "$TRACKER_URL" \
  --repos-root-env "$REPOS_ROOT_ENV" \
  $( [[ "$BOOTSTRAP_KB" == true ]] && echo --bootstrap-kb )
```

`init.sh` es **interactivo si faltan flags**. Pásale todos los valores en CLI para evitar prompts cuando ejecutes desde un agente.

## Paso 2: validar

```bash
scripts/doctor.sh "$TARGET" --json
```

Si la salida contiene `"fail":` con valor > 0, **detente** y reporta al operador qué chequeo ha fallado. No intentes `--fix` automáticamente para fallos en `placeholders` o `required_files`: indican que `init.sh` no completó.

Reparaciones seguras (puedes auto-aplicar):

```bash
scripts/doctor.sh "$TARGET" --fix
```

Solo arregla: permisos de hooks, `index/keywords.json` corrupto, capas KB faltantes.

## Paso 3: editar contexto del proyecto

Estos archivos contienen plantillas que el operador (o tú, si tienes contexto suficiente) debe rellenar:

1. `$TARGET/.claude/skills/knowledge-agent/references/domain.md` — entornos, módulos, invariantes, top issues del proyecto.
2. `$TARGET/.claude/repos.list` — un repo compañero por línea (paths o URLs). El hook `pre-activate.sh` hará `git pull --ff-only` sobre cada uno al activar la skill.
3. Si tracker = `jira`: confirmar que `~/secrets/jira_token.txt` existe; si no, indicárselo al operador.

**No completes `domain.md` con suposiciones.** Si no tienes el contexto, deja la plantilla y pide al operador que la complete.

## Paso 4: smoke test

En una sesión Claude Code dentro de `$TARGET`:

```
/$SLUG status
```

Debe responder con el estado del KB sin errores. Si la skill no se activa, revisar `$TARGET/.claude/skill-rules.json` y `$TARGET/.claude/settings.json`.

## Actualizar una instalación existente

```bash
scripts/upgrade.sh "$TARGET"           # aplica migraciones pendientes
scripts/upgrade.sh "$TARGET" --dry-run # lista sin aplicar
```

Lee `migrations/<version>/NOTES.md` antes de aplicar si quieres saber qué cambia.

## Trust boundary del instalador

- Solo escribe dentro de `$TARGET/.claude/`, `$TARGET/CLAUDE.md` y (si `--bootstrap-kb`) las capas KB.
- **Nunca** edita código fuera de esos paths.
- **Nunca** ejecuta `git commit` o `git push` en el target.
- Si encuentras un `.claude/` preexistente, pregunta antes de sobrescribir.
