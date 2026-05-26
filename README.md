# ckp — Knowledge Agent + Planner

Plugin de Claude Code que aporta el patrón **Knowledge Agent + Planner**:

- Dos skills con responsabilidades separadas (analista de KB ↔ planificador de implementación) comunicadas por un **handoff YAML** auditable.
- Estructura de **Knowledge Base** en capas (`L0-system` … `L7-functional` + `handoff/` + `plans/` + `analysis/`) lista para llenar.
- **Hooks** automáticos para pull de repos compañeros, inyección de contexto KB y keyword-routing.
- **Issue tracker pluggable**: Jira (implementado), Linear y GitHub (stubs).
- Idioma: **Español** (mensajes user-facing, descripciones, triggers).

## Por qué dos skills

| Skill | Rol | Output |
|---|---|---|
| `knowledge-agent` | Analista/arquitecto. Consulta KB, analiza viabilidad, traza impacto, debugging conceptual. No planifica cambios. | `handoff/{id}.yaml` |
| `planner` | Toma el handoff + ticket, lee código real y produce plan con archivos, diffs y criterios verificables. No implementa. | `plans/{id}.md` |

Separarlos mantiene contextos pequeños (KB pesado vs código pesado), permite triggers distintos y crea un artefacto auditable (`handoff`) entre análisis y planificación.

## Instalación

Requiere Claude Code ≥ v2.1.143 (por el campo `displayName` del manifest).

```
/plugin install https://github.com/martialarcon/claude-knowledge-plugin
```

Claude Code pedirá los valores de configuración (`userConfig`):

| Campo | Tipo | Default | Para qué |
|---|---|---|---|
| `kb_path` | directory | *(vacío)* | Subdirectorio del proyecto donde vive el KB. Vacío = el proyecto mismo. |
| `issue_tracker` | string | `none` | `jira` \| `linear` \| `github` \| `none` |
| `issue_prefix` | string | `ISSUE` | Prefijo del ID (ej. `ATP`, `PROJ`) |
| `issue_tracker_url` | string | *(vacío)* | Base URL del tracker, sin slash final |

Si no quieres mover datos, deja `kb_path` vacío: el KB se crea/lee desde la raíz del proyecto.

### Primer uso — bootstrap del KB

```
/ckp:setup
```

Crea las carpetas `L0-system/`…`L7-functional/`, `handoff/`, `plans/`, `analysis/`, `index/keywords.json` y un `.claude/ckp-repos.list` vacío. No sobrescribe nada existente.

Tras `setup`:

1. Edita `<KB>/L0-system/environments.yaml` con los entornos reales.
2. (Opcional) Añade repos compañeros en `<proyecto>/.claude/ckp-repos.list`.
3. (Opcional) Configura `~/secrets/<tracker>_token.txt` si usas Jira.

## Estructura del plugin

```
.claude-plugin/plugin.json    → manifest (userConfig, metadata)
hooks/
  hooks.json                  → PreToolUse / PostToolUse / UserPromptSubmit / SessionEnd
  pre-activate.sh             → pull de repos compañeros + inyecta estado KB (TTL 30 min)
  post-activate.sh            → handoffs pendientes, flag de sesión activa
  on-user-prompt.sh           → keyword-routing contra index/keywords.json
  on-success.sh               → merge de keywords al KB tras /ckp capture
  on-session-end.sh           → limpia flag de sesión
skills/
  knowledge-agent/SKILL.md    → analista/arquitecto
  knowledge-agent/references/{principles,handoff-format,domain}.md
  planner/SKILL.md            → planificador
  planner/references/issue-tracker.md
  planner/references/trackers/{jira,linear,github}.md
  setup/SKILL.md              → bootstrap interactivo del KB
  RESOLVER.md                 → dispatcher KA vs Planner
kb-skeleton/                  → árbol L0…L7 vacío que /ckp:setup copia al KB
scripts/
  doctor.sh                   → health-check del plugin (manifest, hooks, skills)
  validate.sh                 → alias de doctor.sh
examples/{sample-handoff.yaml,sample-plan.md}
```

### Resolución de rutas en runtime

| Recurso | Ubicación |
|---|---|
| Plantillas / código del plugin | `${CLAUDE_PLUGIN_ROOT}` (read-only, efímero) |
| Estado mutable del plugin (`.last-pull`, `.ckp-session-active`, `learning/`) | `${CLAUDE_PLUGIN_DATA}` (persistente entre updates) |
| KB del proyecto (`L*/`, `handoff/`, `plans/`, `index/`) | `${CLAUDE_PROJECT_DIR}/${user_config.kb_path}` |
| Lista de repos compañeros | `${CLAUDE_PROJECT_DIR}/.claude/ckp-repos.list` |

## Comandos

```
/ckp                        # Knowledge Agent (analyze, query, impact, diagnose, handoff…)
/ckp:planner                # Planner (genera plans/{id}.md a partir de handoff)
/ckp:setup                  # Bootstrap del KB en el proyecto actual
```

## Flujo de uso

```
SESIÓN 1 (Knowledge Agent)               SESIÓN 2 (Planner)
/ckp analyze + /ckp handoff PRJ-123  →   /ckp:planner PRJ-123
              ▼                                       ▼
   <KB>/handoff/PRJ-123.yaml             <KB>/plans/PRJ-123.md
```

## Desarrollo

```bash
git clone https://github.com/martialarcon/claude-knowledge-plugin
cd claude-knowledge-plugin
scripts/doctor.sh           # health-check
scripts/doctor.sh --json    # salida estructurada
scripts/doctor.sh --fix     # repara permisos de hooks
```

## Licencia

MIT.
