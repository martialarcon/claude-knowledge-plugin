# v0.2.0 — migración desde 0.1.0

## Qué cambia

- Introduce `.claude/.plugin-version` para tracking.
- Añade `.claude/skills/RESOLVER.md` (dispatcher entre `knowledge-agent` y `planner`).
- Bloque "Trust boundary" inyectado al final de ambos `SKILL.md` si falta.

## Qué NO toca

- `repos.list`, `references/domain.md`, contenidos de `L*/`, `analysis/`, `handoff/`, `plans/`.
- `settings.json` y `skill-rules.json` del operador (solo añade claves nuevas si están ausentes; nunca sobrescribe).

## Riesgos

- Si el operador editó `SKILL.md` y eliminó el marcador `<!-- trust-boundary:start -->`, la inyección reaplicará el bloque. Inocuo.
