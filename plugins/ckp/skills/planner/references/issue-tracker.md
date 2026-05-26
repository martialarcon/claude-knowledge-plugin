# Contrato del issue tracker

El Planner depende de un tracker externo para validar tickets y resolver títulos. Este archivo define el **contrato abstracto**; las implementaciones concretas viven en `trackers/<nombre>.md`.

## Tracker activo

- **Nombre**: `${user_config.issue_tracker}`
- **Implementación**: [`trackers/${user_config.issue_tracker}.md`](trackers/${user_config.issue_tracker}.md)
- **Base URL**: `${user_config.issue_tracker_url}`
- **Prefijo de ID**: `${user_config.issue_prefix}-NNN`

## Contrato (operaciones que el Planner usa)

Cualquier implementación válida debe exponer estas operaciones — vía CLI, curl o helper shell:

### `resolve_issue(id) → { id, title, status, url }`

Dado `${user_config.issue_prefix}-NNN`, devuelve el ticket. Falla si no existe.

**Uso en el Planner:** cuando el handoff trae `issue.title: null` o el usuario aporta solo el ID, el Planner llama a esta operación. Nunca inventa el título.

### `build_url(id) → string`

Devuelve la URL canónica del ticket (ej. `${user_config.issue_tracker_url}/browse/${user_config.issue_prefix}-NNN`).

### `validate_id(id) → bool`

Verifica que `id` cumple el regex `^${user_config.issue_prefix}-\d+$`.

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

Para cambiar de tracker, reconfigura el plugin (`/plugin` → seleccionar `ckp` → editar `issue_tracker`) con valor `jira | linear | github`.
