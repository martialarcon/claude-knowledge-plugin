#!/usr/bin/env bash
# Migración 0.1.0 → 0.2.0
# - Crea .claude/.plugin-version
# - Copia RESOLVER.md si no existe
# - Inyecta bloque "Trust boundary" en SKILL.md si falta

set -euo pipefail

TARGET="${1:?Uso: upgrade.sh <target>}"
TARGET="$(cd "$TARGET" && pwd)"

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "→ v0.2.0: target=$TARGET"

# 1. RESOLVER.md
RESOLVER_SRC="$PLUGIN_ROOT/.claude/skills/RESOLVER.md"
RESOLVER_DST="$TARGET/.claude/skills/RESOLVER.md"
if [[ -f "$RESOLVER_SRC" && ! -f "$RESOLVER_DST" ]]; then
  cp "$RESOLVER_SRC" "$RESOLVER_DST"
  echo "  + RESOLVER.md instalado"
else
  echo "  · RESOLVER.md ya presente o fuente ausente"
fi

# 2. Trust-boundary en SKILL.md (idempotente vía marcadores)
inject_trust_boundary() {
  local skill_file="$1" skill_name="$2"
  [[ -f "$skill_file" ]] || return 0
  if grep -q 'trust-boundary:start' "$skill_file"; then
    echo "  · trust-boundary ya presente en $skill_name"
    return 0
  fi
  cat >> "$skill_file" <<'EOF'

<!-- trust-boundary:start -->
## Trust boundary

Esta skill **NO implementa código**. Si el usuario pide "y ahora hazlo", "implémentalo", "aplica el plan":

1. **No editar archivos del repo objetivo.** Solo se permite escribir dentro del KB (`analysis/`, `handoff/`, `plans/`, `L*/`).
2. Responder: *"Mi rol es planificar/analizar. Para implementar, abre una sesión de Claude Code en el repo objetivo o pide al Developer que aplique `plans/{id}.md`."*
3. Si el plan no existe todavía, derivar al comando correspondiente (`/{{PROJECT_SLUG}} handoff` o `/planner {id}`).

Razón: el contrato del plugin separa análisis ↔ planificación ↔ implementación para mantener handoffs y planes auditables. Mezclar implementación rompe la cadena de revisión.
<!-- trust-boundary:end -->
EOF
  echo "  + trust-boundary inyectado en $skill_name"
}

inject_trust_boundary "$TARGET/.claude/skills/knowledge-agent/SKILL.md" "knowledge-agent"
inject_trust_boundary "$TARGET/.claude/skills/planner/SKILL.md" "planner"

echo "→ v0.2.0 OK"
