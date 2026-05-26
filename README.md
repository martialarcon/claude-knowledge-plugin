# claude-knowledge-plugin

Patrón **Knowledge Agent + Planner** para Claude Code, empaquetado como plugin reutilizable. Aporta:

- Dos skills con responsabilidades separadas (analista de KB ↔ planificador de implementación) comunicados por un **handoff YAML** auditable.
- Estructura de **Knowledge Base** en capas (`L0-system` … `L7-functional` + `handoff/` + `plans/` + `analysis/`) vacía, lista para llenar.
- **Hooks** para activación automática, pull de repos compañeros, inyección de contexto y keyword-routing.
- **Issue tracker pluggable**: Jira (implementado), Linear y GitHub (stubs).
- Idioma: **Español** (mensajes user-facing, descripciones, triggers).

## Por qué dos skills

| Skill | Rol | Output |
|---|---|---|
| `knowledge-agent` | Analista/arquitecto. Consulta KB, analiza viabilidad, traza impacto, debugging conceptual. No planifica cambios. | `handoff/{id}.yaml` |
| `planner` | Toma el handoff + ticket, lee código real y produce plan con archivos, diffs y criterios verificables. No implementa. | `plans/{id}.md` |

Separarlos mantiene contextos pequeños (KB pesado vs código pesado), permite triggers distintos y crea un artefacto auditable (`handoff`) entre análisis y planificación.

## Instalación

### Opción A — adoptar en un proyecto existente

```bash
git clone <url> ~/git/claude-knowledge-plugin
~/git/claude-knowledge-plugin/scripts/init.sh \
  --target ~/git/mi-proyecto \
  --name mi-proyecto \
  --slug ka \
  --kb-path ~/git/mi-proyecto-knowledge \
  --tracker jira \
  --issue-prefix PRJ \
  --tracker-url https://mi-org.atlassian.net
```

Sin flags el script entra en modo interactivo y pregunta cada placeholder.

Tras `init.sh`:

1. Edita `<KB>/.claude/skills/knowledge-agent/references/domain.md` y rellena la sección "Project Context" (entornos, módulos, invariantes).
2. Edita `<KB>/.claude/repos.list` con los repos compañeros que el hook debe mantener actualizados.
3. (Opcional) Configura `~/secrets/<tracker>_token.txt` si vas a usar Jira.

### Opción B — empezar de cero

```bash
scripts/init.sh --target ~/git/nuevo-kb --bootstrap-kb
```

Con `--bootstrap-kb` copia también el árbol `kb-skeleton/` vacío.

## Estructura

```
plugin.json
README.md
CLAUDE.md.template          → se copia a <KB>/CLAUDE.md
.claude/
  settings.json             → hooks PreToolUse / PostToolUse / UserPromptSubmit / SessionEnd
  skill-rules.json          → auto-activación por comandos y keywords
  repos.list.template       → lista de repos compañeros (vacía)
  hooks/                    → 5 hooks bash parametrizados
  skills/
    knowledge-agent/SKILL.md
    knowledge-agent/references/{principles,handoff-format,domain}.md
    planner/SKILL.md
    planner/references/issue-tracker.md          → contrato abstracto
    planner/references/trackers/{jira,linear,github}.md
kb-skeleton/                → árbol L0..L7 vacío con .gitkeep
scripts/
  init.sh                   → bootstrap (flags + interactivo)
  validate.sh               → verifica que no quedan {{placeholders}}
examples/
  sample-handoff.yaml
  sample-plan.md
```

## Placeholders

`init.sh` sustituye en todos los archivos:

| Placeholder | Ejemplo | Qué representa |
|---|---|---|
| `{{PROJECT_NAME}}` | `aecoc` | Nombre del proyecto |
| `{{PROJECT_SLUG}}` | `ka` | Prefijo de comandos (`/ka …`) |
| `{{KB_PATH}}` | `~/git/aecoc-knowledge` | Ruta al knowledge base |
| `{{REPOS_ROOT_ENV}}` | `AECOC_REPOS_ROOT` | Variable de entorno para raíz de repos |
| `{{ISSUE_TRACKER}}` | `jira` | `jira` \| `linear` \| `github` |
| `{{ISSUE_PREFIX}}` | `ATP` | Prefijo del ID (`ATP-123`) |
| `{{ISSUE_TRACKER_URL}}` | `https://aecoc-team.atlassian.net` | Base URL del tracker |

## Validación

```bash
scripts/validate.sh ~/git/mi-proyecto
```

Falla si quedan placeholders `{{…}}` sin sustituir o si las rutas referenciadas en `repos.list` no existen.

## Flujo de uso (post-instalación)

```
SESIÓN 1 (Knowledge Agent)              SESIÓN 2 (Planner)
/ka analyze + /ka handoff PRJ-123  →    /planner PRJ-123
              ▼                                     ▼
   handoff/PRJ-123.yaml                  plans/PRJ-123.md
```

## Licencia

MIT.
