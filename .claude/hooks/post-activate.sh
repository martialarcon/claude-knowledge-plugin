#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# Hook: post-activate.sh
# Tras activar la skill: avisos de entornos cruzados y handoffs pendientes,
# y marca la sesión como activa para que UserPromptSubmit inyecte recordatorio.
# ═══════════════════════════════════════════════════════════════════════════════

set -e

if [[ -f "L0-system/environments.yaml" ]]; then
    warnings=$(grep -c "type: warning" L0-system/environments.yaml 2>/dev/null || echo "0")
    if [[ "$warnings" -gt 0 ]]; then
        echo "⚠️ Hay $warnings advertencias de entornos cruzados activas"
    fi
fi

if [[ -d "handoff/" ]]; then
    pending=$(find handoff/ -name "*.yaml" -exec grep -l "status: pending_planning" {} \; 2>/dev/null | wc -l)
    if [[ "$pending" -gt 0 ]]; then
        echo "📋 $pending handoffs pendientes de planificación"
    fi
fi

touch "$CLAUDE_PROJECT_DIR/.claude/.ka-session-active" 2>/dev/null || true

echo "✅ Skill activada"
