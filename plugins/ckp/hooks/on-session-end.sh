#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# Hook: on-session-end.sh  (plugin: ckp)
# Limpia el flag de sesión activa.
# ═══════════════════════════════════════════════════════════════════════════════

DATA_DIR="${CLAUDE_PLUGIN_DATA:-${CLAUDE_PROJECT_DIR:-$PWD}/.claude}"
rm -f "$DATA_DIR/.ckp-session-active"
exit 0
