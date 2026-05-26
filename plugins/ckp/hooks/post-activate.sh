#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# Hook: post-activate.sh  (plugin: ckp)
# Tras activar la skill: avisos de entornos cruzados y handoffs pendientes,
# y marca la sesión como activa para que UserPromptSubmit inyecte recordatorio.
# ═══════════════════════════════════════════════════════════════════════════════

set -e

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
KB_SUB="${CLAUDE_PLUGIN_OPTION_KB_PATH:-}"
if [[ -n "$KB_SUB" ]]; then
    case "$KB_SUB" in
        /*) KB_ROOT="$KB_SUB" ;;
         *) KB_ROOT="$PROJECT_DIR/$KB_SUB" ;;
    esac
else
    KB_ROOT="$PROJECT_DIR"
fi

DATA_DIR="${CLAUDE_PLUGIN_DATA:-$PROJECT_DIR/.claude}"
mkdir -p "$DATA_DIR"

if [[ -f "$KB_ROOT/L0-system/environments.yaml" ]]; then
    warnings=$(grep -c "type: warning" "$KB_ROOT/L0-system/environments.yaml" 2>/dev/null || echo "0")
    if [[ "$warnings" -gt 0 ]]; then
        echo "⚠️ Hay $warnings advertencias de entornos cruzados activas"
    fi
fi

if [[ -d "$KB_ROOT/handoff" ]]; then
    pending=$(find "$KB_ROOT/handoff" -name "*.yaml" -exec grep -l "status: pending_planning" {} \; 2>/dev/null | wc -l)
    if [[ "$pending" -gt 0 ]]; then
        echo "📋 $pending handoffs pendientes de planificación"
    fi
fi

touch "$DATA_DIR/.ckp-session-active" 2>/dev/null || true

echo "✅ Skill activada"
