# Contrato del issue tracker

El Planner depende de un tracker externo para validar tickets y resolver títulos. Este archivo define el **contrato abstracto**; las implementaciones concretas viven en `trackers/<nombre>.md`.

## Tracker activo

- **Nombre**: `{{ISSUE_TRACKER}}`
- **Implementación**: [`trackers/{{ISSUE_TRACKER}}.md`](trackers/{{ISSUE_TRACKER}}.md)
- **Base URL**: `{{ISSUE_TRACKER_URL}}`
- **Prefijo de ID**: `{{ISSUE_PREFIX}}-NNN`

## Contrato (operaciones que el Planner usa)

Cualquier implementación válida debe exponer estas operaciones — vía CLI, curl o helper shell:

### `resolve_issue(id) → { id, title, status, url }`

Dado `{{ISSUE_PREFIX}}-NNN`, devuelve el ticket. Falla si no existe.

**Uso en el Planner:** cuando el handoff trae `issue.title: null` o el usuario aporta solo el ID, el Planner llama a esta operación. Nunca inventa el título.

### `build_url(id) → string`

Devuelve la URL canónica del ticket (ej. `{{ISSUE_TRACKER_URL}}/browse/{{ISSUE_PREFIX}}-NNN`).

### `validate_id(id) → bool`

Verifica que `id` cumple el regex `^{{ISSUE_PREFIX}}-\d+$`.

## Configuración

Cada implementación documenta:

- Dónde vive el token (`~/secrets/<tracker>_token.txt` recomendado).
- Variables de entorno necesarias.
- Comandos `curl` / CLI de ejemplo.
- Mapeo `git config user.email` ↔ cuenta del tracker (si aplica).

## Stubs disponibles

- ✅ [Jira](trackers/jira.md) — implementación de referencia.
- 🟡 [Linear](trackers/linear.md) — stub. Contrato declarado, recetas no verificadas.
- 🟡 [GitHub Issues](trackers/github.md) — stub. Contrato declarado, recetas no verificadas.

Para activar otro tracker, re-ejecuta `init.sh` con `--tracker linear|github` o sustituye manualmente el placeholder `{{ISSUE_TRACKER}}` en `.claude/skills/`.
