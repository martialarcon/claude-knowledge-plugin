# Formato del handoff KA → Planner

Archivo: `handoff/{{{ISSUE_PREFIX}}-NNN}.yaml` (~500 tokens objetivo).

```yaml
id: {{ISSUE_PREFIX}}-NNN
status: pending_planning           # pending_planning | planned | implemented
created: 2026-05-26T10:00:00Z
created_by: knowledge-agent

issue:
  tracker: {{ISSUE_TRACKER}}
  id: {{ISSUE_PREFIX}}-NNN
  url: {{ISSUE_TRACKER_URL}}/browse/{{ISSUE_PREFIX}}-NNN
  title: <resuelto vía API, nunca inventado>
  label: "{{ISSUE_PREFIX}}-NNN <título corto>"

summary: |
  1-3 frases. Qué se pide, por qué, ámbito.

scope:
  modules:                          # módulos afectados
    - name: <módulo>
      repo: ~/git/<repo>
      branch_hint: feature/{{ISSUE_PREFIX}}-NNN-slug
      files:
        - path: <ruta/archivo.ext>
          why: <para qué mirar aquí>
          anchor: "función X líneas ~100-150"
          current_snippet: |        # ORIENTATIVO, no autoritativo. El Planner relee disco.
            ...
  entities:                         # entidades L2 tocadas
    - <Entity>
  flows:                            # flujos L3 tocados
    - <Flow>

functional_definitions:             # rutas L7 que el Planner DEBE leer
  - L7-functional/<area>/<archivo>.md

decisions_open:                     # bloqueantes que el Planner no puede resolver solo
  - id: D1
    question: <pregunta>
    options:
      - <opción A>
      - <opción B>
    recommendation: <opción + razón corta>

warnings:                           # avisos críticos
  - <riesgo conocido, dependencia, side-effect>

related:
  issues:
    - <{{ISSUE_PREFIX}}-XYZ>: <relación>
  adrs:
    - L6-decisions/<adr>.md

verification_hints:                 # qué se considera "hecho" desde el KA
  - <criterio observable>

links:
  analysis: analysis/<carpeta>/<archivo>.md     # si se generó análisis previo
```

## Reglas

1. **`issue.title`** se resuelve vía API del tracker. **Nunca inventar.**
2. **`current_snippet`** es orientativo: el Planner siempre relee el archivo real en disco antes de proponer diff.
3. **`functional_definitions`** es obligatorio si el plan toca compliance, ciclo de vida o reglas funcionales — el Planner las cruza contra L7.
4. **`decisions_open`** vacío = listo para planificar. No vacío = el Planner pregunta antes.
5. El handoff es **inmutable** una vez `status: planned`. Para añadir info: `/{{PROJECT_SLUG}} handoff-add`.

## Idempotencia

Re-ejecutar `/{{PROJECT_SLUG}} handoff {{ISSUE_PREFIX}}-NNN "…"` con el mismo ID no sobrescribe: pide confirmación y muestra diff.
