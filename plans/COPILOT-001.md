# Plan: COPILOT-001

## Metadata
- Issue: [COPILOT-001](https://github.com/martialarcon/claude-knowledge-plugin) — Exportar sistema Knowledge Agent + Planner para GitHub Copilot (VS Code) — adaptación full
- Handoff: handoff/COPILOT-001.yaml
- Fecha: 2026-05-27
- Estimación: 1.5 días
- Riesgo: bajo

## Resumen

Añadir al plugin una rama de compatibilidad con GitHub Copilot (VS Code) que preserve el workflow KA → Planner → Developer usando mecanismos nativos: instruction files de VS Code, VS Code Tasks como sustituto de hooks, y prompt templates para GitHub.com. El KB L0–L7, los handoff YAML y los plans quedan sin cambios. La instalación se hace con un nuevo script `init-copilot.sh` (mismo patrón que `init.sh`) que genera artefactos en el target.

## Definiciones Funcionales Consultadas

| Archivo L7 | Reglas aplicadas |
|------------|------------------|
| (ninguna — no hay L7 en este repo) | N/A |

## Conflictos con L7 detectados

Ninguno.

## Decisiones

| ID | Pregunta | Decisión | Justificación |
|----|----------|----------|---------------|
| D1 | applyTo global o scoped para instruction files | Global (`"**"`) + activación explícita vía `#knowledge-agent.instructions.md` | Scoping por glob requiere tener archivos de esa carpeta abiertos; la activación manual por referencia es más predecible |
| D2 | Coexistencia `.claude/` + `.vscode/` o exclusivo | Coexistencia total | Son directorios separados sin colisión; un equipo puede usar ambos IDEs |

---

## Módulo: copilot-skeleton (Prioridad: 1)

**Repo:** `~/git/claude-knowledge-plugin`
**Branch:** `claude/workflow-copilot-export-rAuoz`
**Esfuerzo:** 0.75 días
**Riesgo:** bajo

### Archivos a Crear

---

#### `copilot-skeleton/.github/copilot-instructions.md`

**Propósito:** Instrucción always-on para GitHub Copilot. Es el dispatcher (equivalente a RESOLVER.md) fusionado con el contexto de dominio (equivalente a `domain.md`). Siempre activo en VS Code y en github.com/copilot.

```markdown
# {{PROJECT_NAME}} — Copilot Instructions

## Sistema
<!-- Rellena al instalar -->
{{PROJECT_NAME}} es... TODO.

## Módulos y repos

| Módulo | Repo | Stack |
|--------|------|-------|
| TODO   | `~/git/TODO` | TODO |

## Workflow de desarrollo (KA → Planner → Developer)

Este proyecto usa un workflow estructurado de 3 roles:

| Rol | Cómo activar | Qué hace |
|-----|-------------|----------|
| Knowledge Agent (KA) | Menciona `#knowledge-agent.instructions.md` en el chat | Analiza viabilidad, consulta KB, genera handoff YAML |
| Planner | Menciona `#planner.instructions.md` en el chat | Lee handoff, analiza código, genera plan detallado |
| Developer | Chat normal / Copilot Edit | Implementa el plan |

**Flujo completo:**
```
Sesión 1: KA analiza → genera handoff/{{ISSUE_PREFIX}}-NNN.yaml
Sesión 2: Planner lee handoff → genera plans/{{ISSUE_PREFIX}}-NNN.md
Sesión 3: Developer lee plan → implementa
```

## Dispatcher: ¿qué rol usar?

- "analiza viabilidad / es posible / dónde se usa / qué impacto" → **KA** (`#knowledge-agent.instructions.md`)
- "planifica / genera plan / estima esfuerzo" + existe `handoff/` → **Planner** (`#planner.instructions.md`)
- "implementa / escribe código / arregla el bug" → **Developer** (chat normal)
- No sabes cuál → pregunta "¿quieres analizar (KA) o planificar (Planner)?"

## Knowledge Base

El KB está en `{{KB_PATH}}` con esta estructura:

```
L0-system/     → Arquitectura, entornos, branches
L1-modules/    → Detalle por módulo
L2-domain/     → Entidades de negocio
L3-flows/      → Flujos entre módulos
L4-integrations/ → Contratos API
L5-issues/     → Issues abiertos/resueltos
L6-decisions/  → ADRs
L7-functional/ → Especificaciones (fuente de verdad)
handoff/       → Artefactos KA → Planner
plans/         → Planes generados
index/keywords.json → Routing por keywords
```

**Regla:** Consulta siempre `L0-system/environments.yaml` antes de hablar de entornos o branches.

**Para activar routing de keywords:** incluye `#file:{{KB_PATH}}/index/keywords.json` en tu mensaje.

## Issue tracker

- Tracker: {{ISSUE_TRACKER}} — {{ISSUE_TRACKER_URL}}
- Formato de ID: `{{ISSUE_PREFIX}}-NNN`
- **Nunca inventar títulos de tickets.** Si necesitas el título, pide al usuario o resuélvelo vía API.
```

**Verify:** Abrir VS Code en un proyecto con el plugin instalado → Copilot Chat responde preguntas sobre el workflow sin instrucciones adicionales del usuario.

---

#### `copilot-skeleton/.vscode/instructions/knowledge-agent.instructions.md`

**Propósito:** Instruction file de VS Code que activa el rol Knowledge Agent cuando el usuario lo referencia en el chat (`#knowledge-agent.instructions.md`). Contenido: SKILL.md adaptado (sin hooks, sin comandos slash, sin referencias a Claude Code).

```markdown
---
applyTo: "**"
---

# Knowledge Agent — Rol Analista

Eres el Knowledge Agent de {{PROJECT_NAME}}. Analistas funcional + arquitecto. **No implementas código.**

## Tu misión

Consultar el Knowledge Base (`{{KB_PATH}}`), evaluar viabilidad, trazar impacto, diagnosticar problemas y generar handoffs para el Planner.

## Estructura del KB que manejas

```
L0-system/     → Arquitectura, entornos, branches
L1-modules/    → Detalle por módulo
L2-domain/     → Entidades de negocio
L3-flows/      → Flujos entre módulos
L4-integrations/ → Contratos API
L5-issues/     → Issues abiertos/resueltos
L6-decisions/  → ADRs
L7-functional/ → Especificaciones (fuente de verdad)
handoff/       → Artefactos que generas para el Planner
index/keywords.json → Routing por keywords
```

## Principios

1. **KB primero, código después.** Lee `L0-system/` antes de abrir archivos de código.
2. **No inventar.** Si no encuentras algo en el KB, dilo explícitamente.
3. **Mínimo contexto.** Referencia paths del KB; no copies contenido.
4. **Verifiable outcomes.** Ancla conclusiones a archivo, línea o commit concreto.

## Cómo responder

Abre cada respuesta con: `KB consultado: <ruta §sección>` (o `ninguna — propuesta: dónde registrar`).

**Viabilidad:** ✅ VIABLE / ⚠️ VIABLE CON CONDICIONES / ❌ NO VIABLE

## Cuándo generar un handoff

Cuando el usuario confirma que quiere pasar a planificar, genera `handoff/{{ISSUE_PREFIX}}-NNN.yaml` con este esquema mínimo:

```yaml
id: {{ISSUE_PREFIX}}-NNN
status: pending_planning
issue:
  id: {{ISSUE_PREFIX}}-NNN
  title: "<título del ticket — nunca inventar>"
summary: |
  <1-3 frases: qué se pide, por qué, ámbito>
scope:
  modules:
    - name: <módulo>
      files:
        - path: <ruta>
          why: <para qué>
warnings: []
verification_hints:
  - <criterio observable>
```

Usa el formato completo de `handoff/` si necesitas más detalle.

## Lo que NO haces

- No editas archivos del repo objetivo.
- No implementas código.
- Si el usuario pide implementar: "Mi rol es analizar. Para implementar, usa Copilot Edit o pasa el handoff al Planner (`#planner.instructions.md`)."
```

**Verify:** En VS Code Chat, al escribir `#knowledge-agent.instructions.md ¿qué impacto tiene cambiar X?`, Copilot responde en rol KA abriendo con `KB consultado:`.

---

#### `copilot-skeleton/.vscode/instructions/planner.instructions.md`

**Propósito:** Instruction file del Planner. Se activa cuando el usuario referencia este archivo en el chat. Contenido: SKILL.md adaptado sin hooks ni comandos slash.

```markdown
---
applyTo: "**"
---

# Planner — Rol Planificador

Eres el Planner de {{PROJECT_NAME}}. Lees el handoff del Knowledge Agent, analizas el código real en disco y generas un plan detallado con diffs verificables en `plans/{{ISSUE_PREFIX}}-NNN.md`. **No implementas código.**

## Antes de empezar

1. **Verificar que existe `handoff/{{ISSUE_PREFIX}}-NNN.yaml`.** Si no existe, pide al usuario que active el Knowledge Agent primero (`#knowledge-agent.instructions.md`).
2. **Leer el handoff completo.**
3. **Leer los archivos reales en disco** indicados en `scope.modules[].files`. El `current_snippet` del handoff es orientativo; el disco es la fuente de verdad.

## Proceso

1. Cargar `handoff/{{ISSUE_PREFIX}}-NNN.yaml`
2. Leer definiciones funcionales en `L7-functional/` si el handoff las indica
3. Para cada módulo: leer archivos reales, diseñar cambios específicos
4. Resolver decisiones abiertas del handoff (o escalar al usuario)
5. Generar `plans/{{ISSUE_PREFIX}}-NNN.md`

## Estructura del plan que generas

```markdown
# Plan: {{ISSUE_PREFIX}}-NNN

## Metadata
- Issue: {{ISSUE_PREFIX}}-NNN — <título>
- Handoff: handoff/{{ISSUE_PREFIX}}-NNN.yaml
- Fecha: YYYY-MM-DD
- Estimación: X días
- Riesgo: bajo/medio/alto

## Resumen
[Qué se va a hacer]

## Módulo: <nombre> (Prioridad: N)
**Branch sugerida:** feature/{{ISSUE_PREFIX}}-NNN-slug

### Archivos a Crear / Modificar
#### `path/to/file.ext`
```diff
- línea actual
+ línea nueva
```
**Verify:** <criterio observable y binario>

### Definition of Done
- [ ] <criterio verificable>

## Orden de Implementación
## Testing
## Warnings del Knowledge Agent
```

## Criterios verificables (obligatorio)

Cada cambio debe tener un `Verify:` con criterio binario:
- ❌ "que funcione" → ✅ "`test('foo')` devuelve `true`; `test('bar')` devuelve `false`"

## Lo que NO haces

- No implementas código.
- No modificas el handoff.
- Si el usuario pide implementar: "El plan está en `plans/{{ISSUE_PREFIX}}-NNN.md`. Usa Copilot Edit (rol Developer) para aplicarlo."
```

**Verify:** En VS Code Chat, al escribir `#planner.instructions.md #file:handoff/PRJ-123.yaml genera el plan`, Copilot genera `plans/PRJ-123.md` con diffs.

---

#### `copilot-skeleton/.vscode/tasks.json`

**Propósito:** Cuatro tareas que reemplazan los hooks bash. Aparecen en la paleta de tareas de VS Code (`Ctrl+Shift+P → Run Task`). El usuario las ejecuta manualmente en lugar de que se disparen automáticamente.

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "KA: Pre-activate (pull repos)",
      "type": "shell",
      "command": "bash",
      "args": ["${workspaceFolder}/.claude/hooks/pre-activate.sh", "manual", "1.0"],
      "group": "none",
      "presentation": { "reveal": "always", "panel": "shared" },
      "problemMatcher": []
    },
    {
      "label": "KA: Check pending handoffs",
      "type": "shell",
      "command": "bash",
      "args": ["${workspaceFolder}/.claude/hooks/post-activate.sh"],
      "group": "none",
      "presentation": { "reveal": "always", "panel": "shared" },
      "problemMatcher": []
    },
    {
      "label": "KA: Capture session to KB",
      "type": "shell",
      "command": "bash",
      "args": ["${workspaceFolder}/.claude/hooks/on-success.sh", "capture"],
      "group": "none",
      "presentation": { "reveal": "always", "panel": "shared" },
      "problemMatcher": []
    },
    {
      "label": "KA: Clean session flag",
      "type": "shell",
      "command": "bash",
      "args": ["${workspaceFolder}/.claude/hooks/on-session-end.sh"],
      "group": "none",
      "presentation": { "reveal": "always", "panel": "shared" },
      "problemMatcher": []
    }
  ]
}
```

**Verify:** `Ctrl+Shift+P → Tasks: Run Task` muestra las 4 tareas prefijadas "KA:". Ejecutar "KA: Pre-activate" imprime estado del KB.

---

#### `copilot-skeleton/.vscode/extensions.json`

**Propósito:** Recomienda las extensiones necesarias al abrir el proyecto en VS Code.

```json
{
  "recommendations": [
    "GitHub.copilot",
    "GitHub.copilot-chat"
  ]
}
```

**Verify:** Al abrir el proyecto en VS Code, aparece notificación recomendando instalar GitHub Copilot.

---

#### `copilot-skeleton/.github/prompts/ka-analyze.prompt.md`

**Propósito:** Prompt template para el comando "analizar" del KA en GitHub.com/copilot y en VS Code Copilot Chat. El usuario lo guarda y lo reutiliza.

```markdown
---
mode: ask
description: "Knowledge Agent — Analizar viabilidad de un cambio"
---

Actúa como Knowledge Agent de {{PROJECT_NAME}}.

Ticket: ${input:ticketId:{{ISSUE_PREFIX}}-NNN}
Petición: ${input:request:Describe qué quieres cambiar}

1. Consulta primero el KB en `{{KB_PATH}}/`:
   - Siempre: `L0-system/environments.yaml`
   - Si toca entidades: `L2-domain/`
   - Si toca flujos: `L3-flows/`
   - Si hay issues relacionados: `L5-issues/INDEX-open.md`

2. Abre tu respuesta con: `KB consultado: <ruta §sección>`

3. Evalúa viabilidad: ✅ VIABLE / ⚠️ VIABLE CON CONDICIONES / ❌ NO VIABLE

4. Si es viable, indica si procede generar `handoff/{{input:ticketId}}.yaml`.

#file:{{KB_PATH}}/L0-system/environments.yaml
```

**Verify:** El prompt aparece en GitHub.com > Copilot > "Use a saved prompt" y ejecuta el flujo correcto.

---

#### `copilot-skeleton/.github/prompts/planner-run.prompt.md`

**Propósito:** Prompt template para ejecutar el Planner desde GitHub.com/copilot.

```markdown
---
mode: ask
description: "Planner — Generar plan desde handoff"
---

Actúa como Planner de {{PROJECT_NAME}}.

Handoff ID: ${input:handoffId:{{ISSUE_PREFIX}}-NNN}

1. Lee `handoff/${input:handoffId}.yaml`
2. Lee los archivos reales indicados en `scope.modules[].files`
3. Resuelve las `decisions_open` (usa las recomendaciones del handoff si las hay)
4. Genera `plans/${input:handoffId}.md` con diffs verificables

Recuerda: cada cambio necesita `**Verify:**` con criterio binario observable.

#file:handoff/${input:handoffId}.yaml
```

**Verify:** El prompt aparece en GitHub.com > Copilot y genera el plan al completar los inputs.

---

#### `copilot-skeleton/.copilot/activation-guide.md`

**Propósito:** Traducción de `skill-rules.json` a guía legible para el usuario. Explica cuándo y cómo activar cada skill en Copilot (sin automatismo, con instrucciones explícitas).

```markdown
# Guía de Activación de Skills — {{PROJECT_NAME}}

En Claude Code las skills se activan automáticamente. En Copilot el usuario activa
el rol manualmente añadiendo una referencia en el chat.

## Cuándo usar cada rol

### Knowledge Agent → `#knowledge-agent.instructions.md`

Añade esta referencia en el chat cuando:
- "analiza viabilidad de X"
- "es posible añadir Y"
- "dónde se usa Z / quién consume Z / cómo funciona Z"
- "qué impacto tiene cambiar A"
- "genera handoff para {{ISSUE_PREFIX}}-NNN"
- Debugging: "dónde puede estar fallando X"
- Mantenimiento KB: "actualiza conocimiento / captura / registra ADR"

**NO usar cuando:** pides implementar código, escribir tests o aplicar un plan.

### Planner → `#planner.instructions.md`

Añade esta referencia en el chat cuando:
- "planifica la implementación de {{ISSUE_PREFIX}}-NNN"
- "genera el plan desde el handoff"
- "estima el esfuerzo de {{ISSUE_PREFIX}}-NNN"
- Existe `handoff/{{ISSUE_PREFIX}}-NNN.yaml` (si no, usa KA primero)

**NO usar cuando:** no hay handoff previo del KA.

### Developer → (chat normal o Copilot Edit)

Para implementar el plan generado. Referencia el plan como contexto:
`#file:plans/{{ISSUE_PREFIX}}-NNN.md`

## Routing de keywords con el KB

En Claude Code el hook `on-user-prompt.sh` inyecta automáticamente los paths KB
relevantes según keywords. En Copilot debes hacerlo manualmente:

1. Incluye `#file:{{KB_PATH}}/index/keywords.json` en tu mensaje.
2. Copilot sugerirá qué archivos del KB son relevantes.
3. Añade esos archivos como `#file:{{KB_PATH}}/L?-…` en el mismo mensaje.

## Tareas VS Code equivalentes a hooks

Ejecuta desde `Ctrl+Shift+P → Tasks: Run Task`:

| Tarea | Equivalente a | Cuándo |
|-------|---------------|--------|
| KA: Pre-activate (pull repos) | `pre-activate.sh` | Al empezar una sesión KA |
| KA: Check pending handoffs | `post-activate.sh` | Para ver handoffs pendientes |
| KA: Capture session to KB | `on-success.sh capture` | Tras una sesión productiva |
| KA: Clean session flag | `on-session-end.sh` | Al terminar una sesión KA |
```

**Verify:** Un nuevo desarrollador puede seguir la guía desde cero y completar el flujo KA → Planner → Developer en VS Code sin leer otros archivos.

---

### Definition of Done — copilot-skeleton

- [ ] Todos los archivos creados tienen placeholders `{{...}}` (no valores hardcoded)
- [ ] `copilot-instructions.md` tiene el dispatcher completo (KA / Planner / Developer)
- [ ] Instruction files tienen `applyTo: "**"` en el frontmatter
- [ ] `tasks.json` referencia los hooks bash existentes (no duplica lógica)
- [ ] `activation-guide.md` mapea 1:1 los patterns de `skill-rules.json`
- [ ] Prompt templates tienen `mode:` y `description:` en frontmatter

---

## Módulo: scripts/init-copilot.sh (Prioridad: 2)

**Repo:** `~/git/claude-knowledge-plugin`
**Branch:** `claude/workflow-copilot-export-rAuoz`
**Esfuerzo:** 0.5 días
**Riesgo:** bajo

### Archivos a Crear

#### `scripts/init-copilot.sh`

**Propósito:** Instala el `copilot-skeleton/` en un target repo, sustituyendo placeholders. Mismo patrón que `init.sh` (líneas 16–154 de `scripts/init.sh`).

Estructura clave (basada en `init.sh` real):

```bash
#!/usr/bin/env bash
# init-copilot.sh — Bootstrap de artefactos Copilot en un proyecto destino.
#
# Uso:
#   init-copilot.sh --target <path> [--name NAME] [--slug SLUG] [--kb-path PATH]
#                   [--tracker {jira|linear|github}] [--issue-prefix PREFIX]
#                   [--tracker-url URL] [--bootstrap-kb]
#
# Sin flags, modo interactivo.
# Compatible con init.sh — puede ejecutarse sobre el mismo target (coexistencia).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Mismas variables que init.sh (sin REPOS_ROOT_ENV — no aplica a Copilot)
TARGET=""
PROJECT_NAME=""
PROJECT_SLUG=""
KB_PATH=""
ISSUE_TRACKER=""
ISSUE_PREFIX=""
ISSUE_TRACKER_URL=""
BOOTSTRAP_KB=0

# [parsing flags idéntico a init.sh, sin --repos-root-env]
# [función prompt() idéntica a init.sh]
# [validaciones idénticas a init.sh]

# ─── Copia ───────────────────────────────────────────────────────────────────
mkdir -p "$TARGET/.github/copilot-instructions.d"  # por compatibilidad futura
mkdir -p "$TARGET/.vscode"
mkdir -p "$TARGET/.github/prompts"
mkdir -p "$TARGET/.copilot"

cp -R "$PLUGIN_ROOT/copilot-skeleton/.github/." "$TARGET/.github/"
cp -R "$PLUGIN_ROOT/copilot-skeleton/.vscode/." "$TARGET/.vscode/"
cp -R "$PLUGIN_ROOT/copilot-skeleton/.copilot/." "$TARGET/.copilot/"

# No sobreescribir .vscode/tasks.json si ya existe — mergear en su lugar
# (implementación: si existe, añadir las tareas KA: al array existente)

if [[ "$BOOTSTRAP_KB" -eq 1 ]]; then
  cp -R "$PLUGIN_ROOT/kb-skeleton/." "$TARGET/"
fi

# ─── Sustitución de placeholders ─────────────────────────────────────────────
# Función substitute() idéntica a init.sh
# Aplicar sobre: .github/, .vscode/instructions/, .copilot/

# ─── Output ──────────────────────────────────────────────────────────────────
echo "✅ Artefactos Copilot instalados en $TARGET"
echo
echo "Próximos pasos:"
echo "  1. Edita $TARGET/.github/copilot-instructions.md (sección ## Sistema)"
echo "  2. Edita $TARGET/.copilot/activation-guide.md con tus módulos"
echo "  3. Si no tienes KB: añade --bootstrap-kb o ejecuta init.sh"
echo "  4. Instala extensiones: GitHub Copilot + GitHub Copilot Chat"
echo "  5. VS Code: Ctrl+Shift+P → Extensions: Show Recommended Extensions"
```

**Diff real sobre `scripts/init.sh`** — el script nuevo es autónomo, no modifica `init.sh`. La referencia es estructural:

```diff
  # NUEVO ARCHIVO scripts/init-copilot.sh
  # Copia la estructura de init.sh con estos cambios:
- TARGET/.claude/                         # destino claude
+ TARGET/.github/, .vscode/, .copilot/    # destino copilot
- PLUGIN_ROOT/.claude/                    # fuente claude
+ PLUGIN_ROOT/copilot-skeleton/           # fuente copilot
- prompt REPOS_ROOT_ENV ...               # no aplica
+ (eliminado)
- chmod +x "$TARGET/.claude/hooks/"*.sh  # hooks ejecutables
+ (no aplica — tasks.json no es ejecutable)
- cp VERSION → .plugin-version           # stamp versión
+ cp VERSION → .copilot/.plugin-version  # stamp copilot
```

**Verify:** `bash scripts/init-copilot.sh --target /tmp/test-copilot --name test --slug ka --kb-path /tmp/test-copilot --tracker jira --issue-prefix PRJ --tracker-url https://example.atlassian.net` ejecuta sin errores y genera los 7 artefactos con placeholders sustituidos.

---

### Definition of Done — scripts

- [ ] `init-copilot.sh` ejecuta sin errores con flags completos
- [ ] `init-copilot.sh` ejecuta en modo interactivo (sin flags)
- [ ] Todos los placeholders sustituidos en el target
- [ ] Compatible con target que ya tiene `.claude/` (no lo sobreescribe)
- [ ] `.vscode/tasks.json` no sobreescribe uno existente (merge de tareas)
- [ ] `--bootstrap-kb` funciona igual que en `init.sh`

---

## Módulo: plugin.json (Prioridad: 3)

**Repo:** `~/git/claude-knowledge-plugin`
**Branch:** `claude/workflow-copilot-export-rAuoz`
**Esfuerzo:** 0.25 días
**Riesgo:** bajo

### Archivos a Modificar

#### `plugin.json`

**Cambio 1:** Añadir script `init-copilot` y excluir el copilot-skeleton de los archivos excluidos de instalación.

```diff
   "scripts": {
     "init": "scripts/init.sh",
+    "init-copilot": "scripts/init-copilot.sh",
     "validate": "scripts/validate.sh",
     "doctor": "scripts/doctor.sh",
     "upgrade": "scripts/upgrade.sh"
   },
```

```diff
   "excluded_from_install": [
     "migrations/",
     "scripts/upgrade.sh",
     "INSTALL_FOR_AGENTS.md",
     "llms.txt",
-    "VERSION"
+    "VERSION",
+    "plans/",
+    "handoff/"
   ]
```

**Verify:** `cat plugin.json | jq '.scripts["init-copilot"]'` devuelve `"scripts/init-copilot.sh"`.

---

### Definition of Done — plugin.json

- [ ] `jq '.scripts["init-copilot"]'` devuelve path correcto
- [ ] `jq '.excluded_from_install'` incluye `"plans/"` y `"handoff/"`

---

## Orden de Implementación

1. **copilot-skeleton/** — Base de todos los artefactos. Sin este directorio, `init-copilot.sh` no puede funcionar.
2. **scripts/init-copilot.sh** — Requiere que `copilot-skeleton/` exista para poder copiar los archivos.
3. **plugin.json** — Ajuste de manifest. Puede hacerse en paralelo con los anteriores pero lógicamente cierra el módulo.

## Testing

| Módulo | Qué probar | Criterio |
|--------|-----------|---------|
| copilot-skeleton | Placeholders presentes | `grep -r '{{PROJECT_NAME}}' copilot-skeleton/` devuelve ≥5 matches |
| copilot-skeleton | Sin valores hardcoded | `grep -r 'example\.atlassian' copilot-skeleton/` devuelve 0 matches |
| init-copilot.sh | Ejecución completa con flags | Exit 0, 7 archivos generados en target |
| init-copilot.sh | Sustitución de placeholders | `grep '{{PROJECT_NAME}}' /tmp/test-copilot/.github/copilot-instructions.md` devuelve 0 matches |
| init-copilot.sh | Coexistencia con `.claude/` | Ejecutar sobre target con `.claude/` existente; `.claude/` intacto |
| tasks.json | Estructura válida JSON | `jq . copilot-skeleton/.vscode/tasks.json` sin error |
| instruction files | Frontmatter válido | Cada `*.instructions.md` tiene `applyTo:` en las primeras 3 líneas |
| plugin.json | Script registrado | `jq '.scripts["init-copilot"]'` = `"scripts/init-copilot.sh"` |

## Deploy

### Orden
1. Commit en branch `claude/workflow-copilot-export-rAuoz`
2. PR a main

### Rollback
Los nuevos archivos son aditivos (no modifican `.claude/` ni el flujo Claude Code existente). Rollback = revertir el commit o borrar `copilot-skeleton/` y `scripts/init-copilot.sh`.

## Warnings del Knowledge Agent

> VS Code instructions (`.vscode/instructions/`) requieren VS Code ≥1.96 y GitHub Copilot extension habilitada. Versiones anteriores ignoran estos archivos silenciosamente.

> GitHub Copilot NO ejecuta código antes/después de cada prompt. Los hooks de keyword-routing (`on-user-prompt.sh`) no tienen equivalente automático. El usuario debe incluir contexto manualmente vía `#file` references.

> `.github/prompts/` funciona en github.com/copilot pero NO en VS Code Chat. Son superficies distintas. El `init-copilot.sh` debe generar ambas.

> La auto-activación por score (`skill-rules.json`) se pierde completamente. La guía `.copilot/activation-guide.md` educa al usuario pero no la reemplaza.

## Trazabilidad

- Issue: COPILOT-001 — Exportar sistema Knowledge Agent + Planner para GitHub Copilot
- Branch sugerida: `claude/workflow-copilot-export-rAuoz`
- Formato de commit: `COPILOT-001 Add Copilot full export skeleton and init-copilot.sh`

## Checklist Pre-Implementación

- [x] Decisiones D1 y D2 resueltas
- [x] Branch `claude/workflow-copilot-export-rAuoz` existe (branch de trabajo actual)
- [ ] Verificar que VS Code ≥1.96 está disponible para testear instruction files
- [ ] Verificar que GitHub Copilot extension está instalada en el entorno de test
