# Skill Resolver

Léeme **antes** de activar cualquier skill de este plugin. Soy el dispatcher: decido entre `knowledge-agent` (KA) y `planner`. El routing automático por keywords (`skill-rules.json` + hook `on-user-prompt.sh`) es un atajo; este documento es la fuente de verdad cuando hay ambigüedad.

## Árbol de decisión

```
¿La petición pide IMPLEMENTAR código? (editar archivos del repo objetivo)
└── SÍ  → NINGUNA skill de este plugin. Derivar a Developer / Claude Code en el repo objetivo.
          Razón: el plugin separa análisis ↔ plan ↔ implementación por contrato.

¿La petición es planificar/desglosar una tarea concreta ligada a un ticket?
├── SÍ y ya existe handoff/{id}.yaml          → planner
├── SÍ pero NO existe handoff/{id}.yaml       → knowledge-agent (genera handoff primero)
└── NO → siguiente check

¿La petición es entender/analizar/consultar?
├── "dónde se usa", "cómo funciona", "qué impacto", "es viable",
│   "diagrama de", "flujo de", "dónde puede fallar"   → knowledge-agent
└── NO → siguiente check

¿La petición es mantenimiento del KB?
├── "actualiza conocimiento", "captura", "registra ADR",
│   "añade issue", "sync con commits"                  → knowledge-agent
└── NO → preguntar al usuario qué quiere realmente. NO activar a ciegas.
```

## Reglas duras

1. **Planner exige handoff.** Si el usuario pide `/planner {id}` sin `handoff/{id}.yaml`, **no activar planner**. Responder con la receta para generarlo desde KA.
2. **KA exige ticket** para `analyze`, `handoff`, `impact`. Si falta, pedirlo antes de continuar; nunca inventarlo.
3. **Ninguna skill implementa.** Ver bloque "Trust boundary" en cada `SKILL.md`.
4. **Sesiones separadas.** KA y Planner se ejecutan idealmente en sesiones distintas para mantener limpio el contexto y el contrato auditable del handoff YAML. Si comparten sesión, el modelo debe cambiar de skill explícitamente, no continuar con la anterior.

## Señales de keyword (referencia rápida)

| Frase del usuario | Skill |
|---|---|
| "analiza viabilidad de X" | knowledge-agent |
| "es posible añadir Y" | knowledge-agent |
| "dónde se usa Z" / "quién consume Z" | knowledge-agent |
| "qué impacto tiene cambiar A" | knowledge-agent |
| "genera handoff para PRJ-123" | knowledge-agent |
| "planifica PRJ-123" / "haz el plan de PRJ-123" | planner (requiere handoff) |
| "estima esfuerzo de PRJ-123" | planner |
| "implementa PRJ-123" / "aplica el plan" | **ninguna** (Developer) |
| "arregla el bug X" | **ninguna** (Developer) |
| "muestra el flujo de pagos" | knowledge-agent |
| "diagrama de la integración" | knowledge-agent |

## Cuando dudes

Pregunta al usuario una de estas tres:
- *"¿Quieres que analice (KA) o que genere un plan accionable (Planner)?"*
- *"¿Existe ya un `handoff/{id}.yaml` para este ticket?"*
- *"¿Estás esperando una respuesta de análisis o un artefacto en `plans/`?"*

No actives la skill por defecto.
