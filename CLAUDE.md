# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Qué es este repositorio

Plugin de Claude Code (formato nativo, manifest en `.claude-plugin/plugin.json`) que implementa el patrón **Knowledge Agent + Planner**. No es un proyecto de aplicación: el código aquí se ejecuta cuando un usuario instala el plugin (`/plugin install …`) y Claude Code descubre automáticamente las skills, hooks y configuración.

## Comandos principales (desarrollo)

```bash
scripts/doctor.sh           # health-check de la estructura del plugin
scripts/doctor.sh --json    # salida estructurada
scripts/doctor.sh --fix     # repara permisos de hooks
```

`doctor.sh` verifica:
- `.claude-plugin/plugin.json` válido con campos `name`, `version`, `description`.
- `hooks/hooks.json` válido.
- Hooks `*.sh` ejecutables.
- Skills obligatorias (`knowledge-agent`, `planner`, `setup`, `RESOLVER.md`).
- Sin placeholders `{{...}}` residuales en `skills/` o `hooks/`.
- Stubs de trackers (`jira`, `linear`, `github`) presentes.
- `kb-skeleton/` completo (L0–L7 + analysis/handoff/plans/index).

## Arquitectura del plugin

```
.claude-plugin/plugin.json    → manifest + userConfig
hooks/
  hooks.json                  → PreToolUse / PostToolUse / UserPromptSubmit / SessionEnd
  pre-activate.sh             → pull repos compañeros + estado KB (TTL 30 min)
  post-activate.sh            → handoffs pendientes + flag sesión activa
  on-user-prompt.sh           → keyword-routing contra <KB>/index/keywords.json
  on-success.sh               → merge keywords al KB tras /ckp capture
  on-session-end.sh           → limpia flag de sesión
skills/
  knowledge-agent/SKILL.md    → analista (NO implementa)
  planner/SKILL.md            → planificador (NO implementa)
  setup/SKILL.md              → bootstrap interactivo del KB
  RESOLVER.md                 → dispatcher KA vs Planner
kb-skeleton/                  → L0–L7 vacío, copiado por /ckp:setup
scripts/{doctor,validate}.sh
```

### Dos skills, responsabilidades separadas

| Skill | Entrada | Salida | Prohibido |
|---|---|---|---|
| `knowledge-agent` | Preguntas, `/ckp analyze`, `/ckp handoff` | `<KB>/handoff/{id}.yaml` | Implementar código |
| `planner` | `<KB>/handoff/{id}.yaml` + ticket | `<KB>/plans/{id}.md` | Implementar código, modificar handoff |
| `setup` | `/ckp:setup` | Estructura KB en `<KB>` | Sobrescribir KB existente |

El handoff YAML actúa como contrato auditable entre sesiones.

### Configuración via userConfig

El manifest declara estos valores configurables (Claude Code los pide al instalar):

| userConfig | Tipo | Default | Uso |
|---|---|---|---|
| `kb_path` | directory | *(vacío)* | Subdir del proyecto donde vive el KB |
| `issue_tracker` | string | `none` | `jira` \| `linear` \| `github` \| `none` |
| `issue_prefix` | string | `ISSUE` | Prefijo de tickets |
| `issue_tracker_url` | string | *(vacío)* | Base URL del tracker |

Sustitución en runtime:
- En `SKILL.md` (contenido): `${user_config.kb_path}`, etc.
- En scripts bash: `$CLAUDE_PLUGIN_OPTION_KB_PATH`, etc.

### Resolución de rutas

| Recurso | Ubicación |
|---|---|
| Código del plugin (read-only) | `${CLAUDE_PLUGIN_ROOT}` |
| Estado mutable | `${CLAUDE_PLUGIN_DATA}` |
| KB del proyecto | `${CLAUDE_PROJECT_DIR}/${user_config.kb_path}` (si vacío → `${CLAUDE_PROJECT_DIR}`) |
| Repos compañeros | listados en `${CLAUDE_PROJECT_DIR}/.claude/ckp-repos.list`, raíz por `$CKP_REPOS_ROOT` o `dirname(KB)` |

**Regla crítica**: `${CLAUDE_PLUGIN_ROOT}` es efímero — la doc oficial avisa que la versión anterior se elimina ~7 días tras update. Cualquier estado mutable debe ir a `${CLAUDE_PLUGIN_DATA}` o al proyecto.

## Trackers de issues

Jira está implementado. Linear y GitHub son stubs en `skills/planner/references/trackers/`. El usuario selecciona el activo vía `userConfig.issue_tracker`; el SKILL.md del planner hace referencia dinámica con `${user_config.issue_tracker}`.

## Flujo de uso (post-instalación)

```
/ckp:setup                                          # primera vez
       ↓
SESIÓN 1 — Knowledge Agent
  /ckp analyze 'descripción'
  /ckp handoff PRJ-123
         ↓
  <KB>/handoff/PRJ-123.yaml

SESIÓN 2 — Planner
  /ckp:planner PRJ-123
         ↓
  <KB>/plans/PRJ-123.md
```

## Histórico

La rama `master` anterior usaba `scripts/init.sh` para copiar el plugin a `<target>/.claude/` con sustitución de placeholders `{{...}}`. La rama `feat/plugin-format` (v0.3.0) migra al formato nativo de plugins de Claude Code: instalación vía `/plugin install`, configuración por `userConfig`, y publicación opcional en marketplace.
